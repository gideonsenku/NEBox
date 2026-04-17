# Relay macOS 原生应用 - 需求文档

## 功能概述

为 Relay (BoxJS iOS 客户端) 在**同一个 Xcode 项目**内新增原生 macOS 应用，最低支持 macOS 26，采用 macOS 26 的 Liquid Glass 设计语言。

**重要背景**：这是**第二次**尝试添加 macOS 支持。首次尝试（2026-04-03）采用大量 `#if os(iOS)` 条件编译 + 直接复用 iOS 视图，用户对 UI 不满意。本次需求明确要求**重新设计 macOS UI**，而非简单移植 iPhone 界面 —— macOS 版应该遵循平台原生习惯（侧边栏导航、工具栏、窗口管理、鼠标悬停等），而不是放大版的 iPhone 应用。

**复用策略**：
- ✅ **共享**：`Models/`、`ViewModels/`、`Services/`、`Managers/`、`Helpers/`（网络、数据、状态）
- 🔁 **重写**：所有 `Views/` 内的 UI 层 —— 为 macOS 单独编写
- ❌ **不复用**：iOS 端的 UICollectionView 桥接、TabView、手势、触觉反馈等 iPhone 专属实现

---

## 需求列表

### REQ-1: Xcode 项目与 Target 配置

**用户故事**：作为开发者，我想要一个独立的 macOS target 与 iOS target 并存于同一个 Xcode 项目，以便在不影响 iOS 构建的前提下开发 macOS 版本。

**验收标准 (EARS 格式)**：
1. **REQ-1.1** [Ubiquitous]：项目**应当**包含一个名为 `RelayMac`（或 `Relay (macOS)`）的独立 App target，Bundle Identifier 与 iOS 版保持同一前缀（如 `com.senku.relay` / `com.senku.relay.mac`）。
2. **REQ-1.2** [Ubiquitous]：macOS target 的 `MACOSX_DEPLOYMENT_TARGET` **应当**为 `26.0`，`SUPPORTED_PLATFORMS` 包含 `macosx`。
3. **REQ-1.3** [State-driven]：当开发者在 Xcode 中切换 scheme 时，系统**应当**能分别构建和运行 iOS 与 macOS 版本而不互相污染。
4. **REQ-1.4** [Unwanted behavior]：iOS target 的构建设置、依赖、资源**不应当**因引入 macOS target 而受到破坏性影响（iOS 15.0 最低版本保持不变）。
5. **REQ-1.5** [Ubiquitous]：SPM 依赖（Moya / Alamofire / AnyCodable / SDWebImageSwiftUI）**应当**在 macOS target 中同样可用。

### REQ-2: 共享代码复用

**用户故事**：作为开发者，我想要 Models / ViewModels / Services 层完全共享，以便 iOS 与 macOS 端的数据、网络、业务逻辑保持一致。

**验收标准**：
1. **REQ-2.1** [Ubiquitous]：`Models/BoxDataModel.swift`、`ViewModels/BoxJsViewModel.swift`、`Services/` 下全部文件**应当**被 iOS 与 macOS 两个 target 同时引用（Target Membership 双勾）。
2. **REQ-2.2** [Ubiquitous]：`Managers/ApiManager.swift`、`Managers/ToastManager.swift` **应当**跨平台共享，无平台专属代码。
3. **REQ-2.3** [State-driven]：当共享代码需要访问平台 API（如 `UIApplication.open`、`UIPasteboard`、`UIDevice`）时，**应当**通过抽象层（如 `PlatformBridge` / Color 跨平台别名）封装，避免业务代码散布 `#if os`。
4. **REQ-2.4** [Ubiquitous]：`Helpers/Vibration.swift` 在 macOS target 上**应当**提供空实现或 `NSHapticFeedbackManager` 包装，调用方无需改动。
5. **REQ-2.5** [Unwanted behavior]：macOS 端**不应当**出现 `import UIKit` 的硬依赖（仅在 `#if os(iOS)` 守卫内允许）。

### REQ-3: 应用入口与窗口架构

**用户故事**：作为 macOS 用户，我想要使用符合 macOS 习惯的应用入口（Dock 图标、菜单栏、多窗口），而不是被塞进一个全屏 iPhone 模拟窗。

**验收标准**：
1. **REQ-3.1** [Ubiquitous]：macOS App 入口**应当**使用独立的 `@main struct RelayMacApp: App`（与 `RelayApp` 区分），在 `WindowGroup` 中承载主窗口。
2. **REQ-3.2** [Ubiquitous]：主窗口**应当**使用 `NavigationSplitView` 三栏布局：侧边栏（Sidebar）+ 中间列表（可选）+ 详情页（Detail）。
3. **REQ-3.3** [Event-driven]：当用户点击关闭主窗口后重新打开 Dock 图标，系统**应当**恢复到上次窗口大小与侧边栏选择状态。
4. **REQ-3.4** [Ubiquitous]：应用**应当**提供标准菜单栏（App 菜单 / File / Edit / View / Window / Help），至少支持 ⌘, (Settings)、⌘W (Close Window)、⌘Q (Quit)、⌘F (全局搜索)。
5. **REQ-3.5** [Optional]：如果用户点击菜单栏的 "File → Import Backup…"，应用**可以**打开 `NSOpenPanel` 选择 JSON 备份文件导入。
6. **REQ-3.6** [Ubiquitous]：应用**应当**注册 `relay://` URL scheme，支持从浏览器/其它应用跳转到指定应用详情。

### REQ-4: Liquid Glass 设计语言

**用户故事**：作为 macOS 用户，我想要看到符合 macOS 26 Liquid Glass 美学的界面（毛玻璃材质、玻璃按钮、流动高光），而不是 iOS 风格移植。

**验收标准**：
1. **REQ-4.1** [Ubiquitous]：侧边栏**应当**使用 `.glassEffect()` 或 `Material` 背景，在浅色/深色模式下都表现为半透明玻璃材质。
2. **REQ-4.2** [Ubiquitous]：主要操作按钮（添加订阅、运行脚本、保存设置）**应当**采用 Liquid Glass 按钮样式（`.glassButtonStyle()` 或等价的 `.buttonStyle(.glass)`）。
3. **REQ-4.3** [State-driven]：当鼠标悬停在可交互卡片上时，卡片**应当**显示轻微的高光/抬起反馈（Liquid Glass 的 hover highlight）。
4. **REQ-4.4** [Ubiquitous]：窗口工具栏**应当**使用 `.toolbar(.glass)` 样式或与 macOS 26 系统工具栏视觉对齐。
5. **REQ-4.5** [Ubiquitous]：所有系统颜色**应当**使用 `Color(nsColor: .windowBackgroundColor)` 等 macOS 原生语义色，**不应当**直接硬编码 RGB 或使用 iOS UIColor 桥接。
6. **REQ-4.6** [Unwanted behavior]：macOS 版**不应当**使用 `TabView(.page)` / 底部 TabBar / FloatingTabBar 等 iPhone 导航模式。

### REQ-5: 主要功能视图（macOS 重新设计）

**用户故事**：作为用户，我想要在 macOS 上以更高信息密度、更符合桌面习惯的方式管理 BoxJS 应用、订阅源和设置。

**验收标准**：
1. **REQ-5.1** [Ubiquitous]：侧边栏**应当**至少包含：收藏应用 / 订阅源 / 会话 / 脚本编辑器 / 日志 / 备份 / 偏好设置 / 关于。
2. **REQ-5.2** [Ubiquitous]：「收藏应用」详情视图**应当**以 `LazyVGrid`（桌面 ≥ 4 列）或可切换的 List/Grid 形式展示，支持鼠标右键上下文菜单、拖拽排序。
3. **REQ-5.3** [Ubiquitous]：「订阅源」详情视图**应当**以 List + Detail 布局展示，左侧选中订阅，右侧显示该订阅包含的应用。
4. **REQ-5.4** [Ubiquitous]：「应用详情」**应当**使用 Form + Section 布局，单列长表单，支持 macOS 原生 Toggle / Picker / TextField 控件。
5. **REQ-5.5** [State-driven]：当用户在「应用详情」里编辑设置后，保存操作**应当**通过右上角工具栏按钮或 ⌘S 提交。
6. **REQ-5.6** [Ubiquitous]：「脚本编辑器」**应当**支持等宽字体、行号、基础缩进（不强求语法高亮，可后续迭代）。
7. **REQ-5.7** [Ubiquitous]：「日志查看器」**应当**支持搜索过滤、级别筛选、右键复制、Export 到文件（NSSavePanel）。
8. **REQ-5.8** [Ubiquitous]：「备份管理」**应当**支持 Import / Export 通过 NSOpenPanel / NSSavePanel，以及拖放 JSON 文件到窗口即导入。
9. **REQ-5.9** [Optional]：如果应用支持全局搜索，⌘F **可以**打开一个 Spotlight 风格的搜索面板覆盖层。

### REQ-6: 平台差异处理

**用户故事**：作为开发者，我想要 macOS 版不使用 iOS 专属 API，同时保持关键能力等价。

**验收标准**：
1. **REQ-6.1** [Ubiquitous]：剪贴板操作**应当**在 macOS 端使用 `NSPasteboard.general`。
2. **REQ-6.2** [Ubiquitous]：打开外部 URL **应当**使用 `NSWorkspace.shared.open(url)`。
3. **REQ-6.3** [Ubiquitous]：分享/导出**应当**使用 `ShareLink`（如可用）或 `NSSharingServicePicker`。
4. **REQ-6.4** [Ubiquitous]：图片选择**应当**使用 `NSOpenPanel`（过滤 `public.image`）代替 PHPickerViewController。
5. **REQ-6.5** [Ubiquitous]：系统日志**应当**继续使用 `os.log`，日志文件路径适配 `NSApplication` 的 `applicationSupportDirectory`。
6. **REQ-6.6** [State-driven]：当 macOS 版尝试调用振动反馈时，系统**应当**使用 `NSHapticFeedbackManager.defaultPerformer` 或空操作（不报错）。

### REQ-7: 信息保存与网络

**用户故事**：作为用户，我想要 macOS 版和 iOS 版相对独立（各自存各自的 BoxJS 服务器地址、备份、偏好），避免误操作混用。

**验收标准**：
1. **REQ-7.1** [Ubiquitous]：macOS 版**应当**使用自己的 UserDefaults suite（或默认 UserDefaults in its own sandbox），不与 iOS 通过 App Group 共享。
2. **REQ-7.2** [Ubiquitous]：BoxJS 服务器地址、订阅列表、头像、偏好**应当**仅在 macOS 端存储，不向 iOS 同步。
3. **REQ-7.3** [State-driven]：当用户首次启动 macOS 版时，**应当**显示与 iOS 端类似的服务器地址引导界面（可以是玻璃卡片式 Sheet）。
4. **REQ-7.4** [Ubiquitous]：网络请求**应当**复用 `NetworkProvider` 与 `BoxJSAPI` 原样不变，信任 `NSAllowsArbitraryLoads` 在 macOS target 的 Info.plist 中的配置。

---

## 边缘情况

1. **EC-1**：某些 BoxJS 服务器仅支持 HTTP（非 HTTPS） → macOS Info.plist 需开启 `NSAllowsArbitraryLoads`。
2. **EC-2**：`AnyCodable` 解析 BoxJS 动态 JSON 字段 → 跨平台无差异，直接复用。
3. **EC-3**：macOS 深色/浅色模式动态切换 → 侧边栏、玻璃材质需实时响应 `colorScheme` 变化。
4. **EC-4**：多窗口场景 → 可选支持 `WindowGroup` 多开，或限制为单窗口（首次实现建议单窗口）。
5. **EC-5**：iPad 版是否同步支持 → **不在本次需求范围**，仅做 iPhone + macOS 双平台。
6. **EC-6**：macOS 26 尚未正式发布（当前日期 2026-04-17） → Liquid Glass API 已公开但部分控件可能仍在迭代，需要针对可用 API 做容错。

---

## 技术约束

1. **TC-1**：最低系统版本 = macOS 26.0，无需向下兼容。
2. **TC-2**：开发工具 Xcode 26+（匹配 macOS 26 SDK）。
3. **TC-3**：必须在**同一个** `Relay.xcodeproj` 中新增 target，不新建独立项目。
4. **TC-4**：iOS target（Relay）保持现状，最低 iOS 15.0 不变。
5. **TC-5**：所有共享文件必须通过 Target Membership 双勾引用，避免物理复制。
6. **TC-6**：Liquid Glass API 在 macOS 26 SDK 提供，需用 `@available(macOS 26.0, *)` 标注（macOS target 最低已是 26，因此大多数场景可省略）。

---

## 成功标准

1. **SC-1**：Xcode 中可分别构建 iOS 和 macOS 两个 scheme，均零错误。
2. **SC-2**：macOS 版启动后呈现 NavigationSplitView 主窗口，侧边栏项目齐全，可导航到各主要功能区。
3. **SC-3**：用户能在 macOS 版完成至少一条端到端流程：配置服务器地址 → 查看收藏应用 → 打开某个应用详情 → 修改设置 → 保存。
4. **SC-4**：视觉审核通过 —— 界面呈现 macOS 26 Liquid Glass 特征（玻璃材质、原生工具栏、无 iPhone 风格痕迹）。
5. **SC-5**：iOS target 构建结果与代码行为未发生回归（可通过 CI 构建验证）。
6. **SC-6**：macOS target 的仓库增量代码集中于新的 `RelayMac/Views/` 目录下，与 iOS 视图物理分离、逻辑隔离。

---

## 范围之外 (非目标)

- ❌ Mac Catalyst（本次采用纯 AppKit + SwiftUI 原生方案，非 Catalyst 方案）
- ❌ 菜单栏常驻（MenuBarExtra）—— 可选后续迭代
- ❌ 多窗口场景 / 多文档模型
- ❌ iCloud 同步 iOS ↔ macOS 数据
- ❌ App Store 发布流程（仅本地构建/签名）
- ❌ 脚本编辑器的语法高亮、调试器
- ❌ 重构 iOS 端已有功能
