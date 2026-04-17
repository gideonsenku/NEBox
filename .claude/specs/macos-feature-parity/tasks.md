# Relay macOS 功能对齐 - 实施任务清单

## 概述

按依赖关系分为 **6 个批次**，共 **22 个原子任务**。CLAUDE_ONLY_MODE，所有任务使用 Claude 执行器。

批次顺序：
- **批次 1**：共享/路由/侧栏扩展（基础层，其余批次依赖）
- **批次 2**：Preferences 扩展（独立，快速见效）
- **批次 3**：Profile 页（新增视图）
- **批次 4**：搜索页（新增视图 + SidebarItem 已在批次 1 就位）
- **批次 5**：备份详情（新增视图 + MacRoute 已在批次 1 就位）
- **批次 6**：Session + Scripts（最复杂，留到最后）

---

## 批次 1: 基础扩展（串行依赖）

| ID  | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|-----|------|--------|------|------|----------|
| 1.1 | `SidebarItem` 新增 `.search` 和 `.profile` 两枚（对应分组、title、SF Symbol） | Claude | 3min | - | `RelayMac/Views/RootWindow/SidebarItem.swift` |
| 1.2 | `MacRoute` 新增 `.backup(id:)` case | Claude | 2min | - | `RelayMac/Views/RootWindow/MacRoute.swift` |
| 1.3 | `MacRouteDestination` 补 `.backup` 路由解析（指向 MacBackupDetailView） | Claude | 3min | 1.2 | `RelayMac/Views/RootWindow/MacRouteDestination.swift` |
| 1.4 | `DetailRouter` 补 `.search` / `.profile` 新增侧栏项的路由 | Claude | 3min | 1.1 | `RelayMac/Views/RootWindow/DetailRouter.swift` |
| 1.5 | 共享 ViewModel 新增 `cloneAppSession(_:)` 方法 | Claude | 4min | - | `Relay/ViewModels/BoxJsViewModel.swift` |
| 1.6 | 构建验证：RelayMac 编译通过（无真实 View 前先建空占位避免 DetailRouter 报错） | Claude | 2min | 1.4 | 构建日志 |

**批次完成标准**：RelayMac 构建成功，侧栏多出 2 条目（空 placeholder 视图），共享 ViewModel 新方法存在。

---

## 批次 2: Preferences 完整偏好（并行，独立）

| ID  | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|-----|------|--------|------|------|----------|
| 2.1 | 扩展 `MacPreferencesView`：新增「BoxJS 偏好」Section，8 个 Toggle | Claude | 5min | 1.6 | `RelayMac/Views/Preferences/MacPreferencesView.swift` |
| 2.2 | 实现 `boolBinding(key:)` 辅助（读 `usercfgs.xxx`，写 `updateData(path:data:)`） | Claude | 4min | 2.1 | 同上 |
| 2.3 | 未配置服务器时禁用 Toggle + 显示提示 | Claude | 2min | 2.1 | 同上 |
| 2.4 | 构建验证 | Claude | 2min | 2.3 | - |

**批次完成标准**：构建通过；运行时 Preferences 页能看到 8 个 Toggle，切换后调用 `updateData`。

---

## 批次 3: Profile 页（并行）

| ID  | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|-----|------|--------|------|------|----------|
| 3.1 | 创建 `MacProfileView`（Form 骨架 + 3 Section） | Claude | 5min | 1.6 | `RelayMac/Views/Profile/MacProfileView.swift` |
| 3.2 | Avatar Section + 显示优先级（AvatarStorage > URL > 默认） | Claude | 5min | 3.1 | 同上 |
| 3.3 | `EditAvatarPopover`：NSOpenPanel 选本地图片 + 粘贴 URL | Claude | 5min | 3.2 | `RelayMac/Views/Profile/EditAvatarPopover.swift` |
| 3.4 | 昵称 inline 编辑（TextField + Enter 保存） | Claude | 3min | 3.1 | `MacProfileView.swift` |
| 3.5 | 玻璃统计卡片（应用/订阅/会话 3 张） | Claude | 5min | 3.1 | `RelayMac/Views/Profile/StatsCard.swift` |
| 3.6 | 替换 DetailRouter 的 profile 占位为 MacProfileView | Claude | 2min | 3.5 | `DetailRouter.swift` |
| 3.7 | 构建验证 | Claude | 2min | 3.6 | - |

**批次完成标准**：侧栏点「个人资料」显示完整 Profile 页，可编辑昵称、切换头像。

---

## 批次 4: 全局搜索（并行）

| ID  | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|-----|------|--------|------|------|----------|
| 4.1 | 创建 `SearchResultRow`（图标 + name/id + author + star 按钮） | Claude | 5min | 1.6 | `RelayMac/Views/Search/SearchResultRow.swift` |
| 4.2 | 创建 `MacSearchView`（NavigationStack + .searchable + 过滤 boxData.apps） | Claude | 5min | 4.1 | `RelayMac/Views/Search/MacSearchView.swift` |
| 4.3 | 星标切换调用 `updateData(path: "usercfgs.favapps", data:)` | Claude | 4min | 4.2 | 同上 |
| 4.4 | 替换 DetailRouter 的 search 占位为 MacSearchView | Claude | 2min | 4.2 | `DetailRouter.swift` |
| 4.5 | 构建验证 | Claude | 2min | 4.4 | - |

**批次完成标准**：侧栏「搜索」可过滤应用，点击星标切换收藏，点击行推入 AppDetail。

---

## 批次 5: 备份详情 + Revert（并行）

| ID  | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|-----|------|--------|------|------|----------|
| 5.1 | 创建 `MacBackupDetailView` 骨架（Hero + 名称 + JSON 预览） | Claude | 5min | 1.3 | `RelayMac/Views/Backup/MacBackupDetailView.swift` |
| 5.2 | 工具栏动作：Revert（NSAlert 确认）、复制 JSON、导出（NSSavePanel） | Claude | 5min | 5.1 | 同上 |
| 5.3 | 名称 TextField inline 编辑 + Enter 保存 | Claude | 3min | 5.1 | 同上 |
| 5.4 | 修改 `MacBackupView`：行变 NavigationLink(value: .backup(id:)) | Claude | 3min | 5.1 | `RelayMac/Views/Backup/MacBackupView.swift` |
| 5.5 | 构建验证 | Claude | 2min | 5.4 | - |

**批次完成标准**：备份列表点击可进入详情，可执行 Revert、复制 JSON、导出、改名。

---

## 批次 6: Session 管理 + 脚本运行（串行）

| ID  | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|-----|------|--------|------|------|----------|
| 6.1 | 创建 `SessionRow`（序号 + 名 + 激活指示 + 数据摘要） | Claude | 5min | 1.5 | `RelayMac/Views/AppDetail/SessionRow.swift` |
| 6.2 | 创建 `SessionListSection`（ForEach + contextMenu + swipeActions + 新建） | Claude | 5min | 6.1 | `RelayMac/Views/AppDetail/SessionListSection.swift` |
| 6.3 | 创建 `RenameSessionPopover`（TextField + 保存） | Claude | 4min | 6.2 | `RelayMac/Views/AppDetail/RenameSessionPopover.swift` |
| 6.4 | 创建 `ScriptsSection`（脚本行 + 运行按钮 + loading + Toast） | Claude | 5min | 1.5 | `RelayMac/Views/AppDetail/ScriptsSection.swift` |
| 6.5 | 修改 `MacAppDetailView`：插入 Session + Scripts Section，集成 Popover | Claude | 5min | 6.3, 6.4 | `RelayMac/Views/AppDetail/MacAppDetailView.swift` |
| 6.6 | 双构建验证（iOS + macOS），修复任何编译错误 | Claude | 5min | 6.5 | - |

**批次完成标准**：应用详情里能看到 Session 列表（带右键 + swipe + 重命名），脚本区可运行脚本看到 Toast；iOS 构建无回归。

---

## 执行策略

### 批次执行顺序

```
批次 1 (串行) → 批次 2 (并行)
            → 批次 3 (并行)
            → 批次 4 (并行)
            → 批次 5 (并行)
            → 批次 6 (串行)
```

> 批次 2-5 在共享基础（批次 1）就绪后可**并行启动**（互不依赖），但建议串行执行以便每批独立验证构建。

### 预估时间

| 批次 | 任务数 | 预估 |
|------|--------|------|
| 批次 1 | 6 | 15 min |
| 批次 2 | 4 | 10 min |
| 批次 3 | 7 | 25 min |
| 批次 4 | 5 | 15 min |
| 批次 5 | 5 | 15 min |
| 批次 6 | 6 | 25 min |
| **总计** | **33** | **~105 min** |

### 批次验证规则

- 每批完成后**立即运行** `xcodebuild -scheme RelayMac -destination 'platform=macOS' build`
- 构建成功才进入下一批；失败则修复当批任务
- 批次 6 完成后**额外运行** iOS 构建（回归检查）

### 原子任务原则

- 每个任务 ≤ 5 min（批次 1.6 等单纯构建验证 ≤ 2 min）
- 任务单一文件或小主题
- 批次完成后**立即** `TaskUpdate` + 构建验证

---

## 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| Form 内 swipeActions 不工作 | 中 | 预案：只保留 contextMenu |
| Popover 在 Form 内定位异常 | 中 | 回退到 Sheet |
| NSOpenPanel 在沙箱下 failing | 低 | entitlements 已有 `com.apple.security.files.user-selected.read-write` |
| usercfgs Toggle 字段在初始 BoxDataResp 为 nil | 中 | 默认值 false；首次写入补全 |
| 脚本 URL 相对路径（BoxJS 返回 /xxx.js）导致 404 | 中 | 注意运行 script 的 URL resolving 逻辑 |
