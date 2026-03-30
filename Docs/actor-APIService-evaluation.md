# 评估：将网络层重构为 actor APIService 的技术方案

> 2026-03-30 评估记录，待后续讨论决定是否实施

## Context

有 iOS 开发者提议将当前的网络层（Moya TargetType + NetworkProvider + ApiManager）重构为一个 Swift actor `APIService`，统一管理 API 请求，并通过 `apiType` 枚举区分不同代理工具的 API 路径差异。需要评估该方案与当前架构的适配性。

## 当前架构分析

| 组件 | 职责 |
|---|---|
| `BoxJSAPI` (Moya enum) | 定义所有端点的 path/method/params |
| `NetworkProvider` (static) | 发起请求 + mapBoxJS 响应校验 |
| `ApiRequest` (static helpers) | 高级参数组装、业务校验 |
| `ApiManager` (singleton) | 管理 baseURL，持久化到 UserDefaults |
| `BoxJsViewModel` | 持有状态，调用网络层，@MainActor 保护 |

**关键事实：当前所有代理工具（Loon/Surge/Shadowrocket/QX）使用完全相同的 BoxJS HTTP API 路径。** 代理工具类型仅通过服务端响应的 `syscfgs.env` 字段检测，不影响请求路径或参数。

## 方案评估

### 优点

1. **actor 隔离** — 用 Swift actor 替代当前零散的 @MainActor 注解和手动并发守卫（如 `isFlushingPendingDataUpdates`），天然解决线程安全问题，为 Swift 6 strict concurrency 做准备
2. **配置内聚** — host/port/auth header 封装在 actor 实例中，切换服务器时销毁重建，比当前 `ApiManager` singleton + didSet 的方式更干净，避免残留状态
3. **可测试性** — actor 可以通过 protocol 抽象，注入 mock 实现，比当前 static 方法更易测试

### 问题与风险

1. **apiType 路径分发目前没有实际需求**
   - 当前所有代理工具共享相同的 BoxJS API（`/query/*`, `/api/*`）
   - `switch(apiType)` 分发不同 path 的设计**解决的是一个不存在的问题**
   - 除非有明确的路线图要支持非 BoxJS 的原生 API（如 Surge HTTP-API 的 CRUD），否则是过度设计

2. **Moya 层会被架空**
   - 当前 Moya TargetType 已经很好地封装了 path/method/params/encoding
   - 如果把路径分发逻辑移到 actor 的 `switch(apiType)` 中，Moya 的 TargetType 模式就失去意义
   - 要么全面替换 Moya（用 URLSession），要么保留 Moya 但不要在 actor 中重复路由逻辑

3. **销毁重建的代价**
   - actor 销毁重建意味着进行中的请求、pending data updates、缓存都会丢失
   - 当前的 `pendingDataUpdates` 批量刷新机制需要迁移到 actor 内部，切换时需先 flush
   - 需要仔细处理生命周期，避免 race condition

4. **ViewModel 耦合加深**
   - 当前 ViewModel 通过 static 方法调用网络层，耦合较松
   - ViewModel 直接持有 actor 实例并管理其生命周期，耦合会加深
   - 但如果通过 protocol 抽象，这个问题可以缓解

## 建议

**不建议按原方案全盘实施**，但可以分步采纳其中有价值的部分：

### 值得做的

- 将 `ApiManager` 的配置（host/port）和 `NetworkProvider` 的请求能力合并为一个 actor，替代当前的 singleton + static 方法组合
- 将 `pendingDataUpdates` 的批量管理移入 actor，利用 actor 隔离替代手动并发守卫
- 通过 protocol 抽象 actor 接口，提升可测试性

### 不建议做的

- 不要加 `apiType` + `switch` 路径分发 — 当前所有工具共享相同 API，没有实际需求
- 不要移除 Moya — 它提供的 TargetType 模式、参数编码、响应映射仍然有价值
- 不要在切换服务器时销毁重建 actor — 改为 actor 内部提供 `reconfigure(host:port:)` 方法，先 flush pending 再切换，更安全

## 验证方式

如果决定实施，应：

1. 先确认是否真的需要支持不同代理工具的不同 API 路径（询问提议者具体场景）
2. 写一个最小 prototype actor 替换 NetworkProvider + ApiManager，验证 Moya 兼容性
3. 确保 `pendingDataUpdates` 在 reconfigure 时被正确 flush
4. 运行全功能回归测试（备份/恢复、订阅管理、会话切换、服务器切换）
