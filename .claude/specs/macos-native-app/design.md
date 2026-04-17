# Relay macOS 原生应用 - 设计文档

## 概述

在现有 `Relay.xcodeproj` 中新增 **`RelayMac` target**，复用 Models/ViewModels/Services 共享代码，为 macOS 26+ 编写**全新的原生 SwiftUI 界面**，采用 NavigationSplitView + Liquid Glass 设计语言。目标是产出体验接近 macOS 原生应用（如 Mail、Reminders、Tips）的 BoxJS 客户端。

### 设计目标

1. **隔离重写**：iOS 视图与 macOS 视图物理分离，不在同一个 `.swift` 文件里铺满 `#if os` 分支
2. **最大复用**：所有网络、数据、业务逻辑（`BoxJsViewModel`、`NetworkProvider`、`BoxJSAPI`）保持单一实现
3. **macOS 原生体验**：侧边栏导航、工具栏操作、键盘快捷键、窗口状态保存、NSOpenPanel / NSPasteboard
4. **Liquid Glass 优先**：优先使用 macOS 26 的 `.glassEffect()` / `Material.ultraThinMaterial`，所有控件走系统默认 SwiftUI（不手搓视觉）
5. **零回归**：iOS target 功能、构建、最低版本完全不变

---

## 架构

### 整体架构

```mermaid
flowchart TD
    subgraph Shared["共享层 (Target Membership: Relay + RelayMac)"]
        Models[Models/BoxDataModel.swift]
        VM[ViewModels/BoxJsViewModel.swift]
        Services[Services/*]
        ApiMgr[Managers/ApiManager.swift]
        ToastMgr[Managers/ToastManager.swift]
        LogMgr[Managers/LogManager.swift]
        Helpers[Helpers/* (除 Vibration)]
    end

    subgraph iOSOnly["iOS Only (Target: Relay)"]
        RelayApp[RelayApp.swift]
        iOSViews[Views/* 全部]
        VibIOS[Helpers/Vibration.swift]
    end

    subgraph macOSOnly["macOS Only (Target: RelayMac)"]
        RelayMacApp[RelayMacApp.swift]
        MacViews[RelayMac/Views/*]
        VibMac[RelayMac/Platform/Vibration+macOS.swift]
        Bridge[RelayMac/Platform/PlatformBridge+macOS.swift]
    end

    iOSViews --> VM
    MacViews --> VM
    VM --> Services
    Services --> ApiMgr
    iOSViews --> ToastMgr
    MacViews --> ToastMgr
```

### Target 与文件组织

```
Relay.xcodeproj/
├── Relay/                         ← iOS target (现有，保持不变)
│   ├── RelayApp.swift             [仅 iOS]
│   ├── Views/                     [仅 iOS，所有文件 Target = Relay]
│   ├── Models/                    [共享，Target = Relay + RelayMac]
│   ├── ViewModels/                [共享]
│   ├── Services/                  [共享]
│   ├── Managers/                  [共享]
│   ├── Helpers/
│   │   ├── AvatarStorage.swift    [共享，需抽象 UIImage/NSImage]
│   │   ├── Utils.swift            [共享，showTextFieldAlert 仅 iOS]
│   │   └── Vibration.swift        [仅 iOS]
│   ├── Extension/
│   │   ├── ArrayExtension.swift   [共享]
│   │   ├── GlobalToastView.swift  [共享，使用跨平台 Color]
│   │   └── ViewModifier.swift     [需拆分：共享部分 + iOS 专有部分]
│   ├── Assets.xcassets            [共享]
│   └── Info.plist                 [仅 iOS]
│
└── RelayMac/                      ← macOS target (新增)
    ├── RelayMacApp.swift          [入口]
    ├── Views/
    │   ├── RootWindow/
    │   │   ├── MainWindowView.swift
    │   │   └── SidebarView.swift
    │   ├── Home/
    │   │   └── MacHomeView.swift
    │   ├── Subscribe/
    │   │   ├── MacSubscribeListView.swift
    │   │   └── MacSubscribeDetailView.swift
    │   ├── AppDetail/
    │   │   └── MacAppDetailView.swift
    │   ├── Preferences/
    │   │   └── MacPreferencesView.swift
    │   ├── Logs/
    │   │   └── MacLogViewerView.swift
    │   ├── Backup/
    │   │   └── MacBackupView.swift
    │   ├── Script/
    │   │   └── MacScriptEditorView.swift
    │   ├── Onboarding/
    │   │   └── MacOnboardingSheet.swift
    │   └── Components/
    │       ├── GlassCard.swift
    │       ├── GlassToolbarStyle.swift
    │       └── MacToast.swift
    ├── Platform/
    │   ├── PlatformBridge+macOS.swift
    │   ├── Pasteboard+macOS.swift
    │   ├── URLOpener+macOS.swift
    │   └── Vibration+macOS.swift      [空实现/NSHapticFeedbackManager]
    ├── Assets.xcassets                [macOS 专用图标]
    ├── Info.plist                     [macOS 专用]
    └── RelayMac.entitlements
```

### 组件职责表

| 组件                            | 职责                                         | 依赖                                     |
|---------------------------------|----------------------------------------------|------------------------------------------|
| `RelayMacApp`                   | App 入口、WindowGroup、菜单命令、环境对象注入 | `MainWindowView`, `BoxJsViewModel`       |
| `MainWindowView`                | `NavigationSplitView` 根容器 + 工具栏        | `SidebarView`, 各 detail view            |
| `SidebarView`                   | 左侧导航列表，持有当前选中项                 | `@Binding var selection: SidebarItem`    |
| `MacHomeView`                   | 收藏应用网格（LazyVGrid）                    | `BoxJsViewModel.boxData`                 |
| `MacSubscribeListView` + Detail | 订阅源 List + 应用 Detail                    | `BoxJsViewModel.sessions`/AppSubCache    |
| `MacAppDetailView`              | 应用设置 Form                                | `BoxJsViewModel.updateDataAsync`         |
| `MacOnboardingSheet`            | 首次启动配置 BoxJS 服务器地址                | `ApiManager`                             |
| `PlatformBridge`                | 剪贴板/URL 打开/分享/图片选择的 macOS 实现   | AppKit                                   |

---

## 核心设计决策

### 决策 1：单项目双 Target，而不是 Catalyst

| 方案                              | 优势                                     | 劣势                                          | 本次选择 |
|-----------------------------------|------------------------------------------|-----------------------------------------------|----------|
| A. Mac Catalyst                   | 零额外代码                               | UI 像 iPad、Liquid Glass 支持有限、视觉不原生 | ❌       |
| **B. 独立 macOS target（本次）**   | 原生外观、可自由重写 UI、Liquid Glass 完整 | 需要维护两套 View                             | ✅       |
| C. 新 Xcode 项目                  | 完全独立                                 | 代码复用困难、SPM/资源重复配置                | ❌       |

### 决策 2：Target Membership 策略

共享文件通过 Xcode 的 Target Membership 双勾实现，**不物理复制**。iOS 专属代码放在 `#if os(iOS)` 保护下或仅被 iOS target 引用。macOS 专属代码放在 `RelayMac/` 目录，仅被 macOS target 引用。

### 决策 3：共享层需要的小量抽象

为避免共享代码里出现 `#if os(iOS) UIPasteboard #else NSPasteboard #endif`，在 **`Extension/` 或 `Helpers/`** 新增跨平台工具：

```swift
// Helpers/PlatformColors.swift（共享）
import SwiftUI
extension Color {
    static var _systemGroupedBackground: Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    static var _tertiarySystemFill: Color {
        #if os(iOS)
        return Color(.tertiarySystemFill)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }
    // ... 其他别名
}
```

```swift
// 其它抽象：
// Helpers/PlatformPasteboard.swift    → copyString / readString
// Helpers/PlatformURLOpener.swift     → openURL(_:)
// Helpers/PlatformImage.swift         → typealias PlatformImage = UIImage | NSImage
```

**原则**：抽象只做现有共享代码真正需要的（AvatarStorage、Utils 里的剪贴板/URL 打开），不做预先过度设计。iOS View 内部仍然可以直接用 UIKit，不受影响。

### 决策 4：Liquid Glass 使用策略

| 场景           | 首选 API                                | 回退           |
|----------------|------------------------------------------|----------------|
| 侧边栏背景     | `.glassEffect()` 或 `Material.sidebar`   | `Material.bar` |
| 工具栏按钮     | `.buttonStyle(.glass)`（macOS 26）       | `.borderless`  |
| 卡片/弹层      | `.glassEffect(in: .rect(cornerRadius:))` | `Material.ultraThinMaterial` |
| Detail 背景    | `Color(nsColor: .windowBackgroundColor)` + `.background(.regularMaterial)` |
| 悬浮菜单/Sheet | `.presentationBackground(.glass)`        | `.ultraThinMaterial` |

**原则**：
- 依靠系统控件自身的玻璃样式，不手搓 `ZStack + .blur + gradient`
- 深色/浅色模式由系统控件自适应
- `@available(macOS 26.0, *)` 检查在 macOS target 上可省略（target 最低就是 26）

### 决策 5：数据隔离

两个 target 使用各自的沙箱和 Bundle Identifier（例如 `com.senku.relay` 和 `com.senku.relay.mac`），UserDefaults 天然隔离。不启用 App Group，不做 iCloud 同步。Onboarding Sheet 首次启动时单独引导配置 BoxJS 服务器地址。

---

## 导航与界面规格

### 顶层结构

```
RelayMacApp
└── WindowGroup("Relay")
    └── MainWindowView
        ├── (if needs onboarding) .sheet → MacOnboardingSheet
        └── NavigationSplitView
            ├── SidebarView (列宽 200-260pt，可折叠)
            │   ├── "应用"
            │   │   ├── 收藏 (home)
            │   │   └── 搜索 (search)
            │   ├── "订阅"
            │   │   └── 订阅源 (subscriptions)
            │   ├── "工具"
            │   │   ├── 脚本编辑器 (scripts)
            │   │   ├── 日志 (logs)
            │   │   └── 备份 (backup)
            │   └── "系统"
            │       ├── 偏好设置 (preferences)
            │       └── 关于 (about)
            └── Detail (根据 selection 路由)
                ├── MacHomeView
                ├── MacSubscribeListView (双栏内部，左 List 右 Detail)
                ├── MacAppDetailView (Form)
                ├── MacScriptEditorView
                ├── MacLogViewerView
                ├── MacBackupView
                ├── MacPreferencesView
                └── MacAboutView
```

### 侧边栏项枚举

```swift
enum SidebarItem: String, Hashable, CaseIterable, Identifiable {
    case home, search, subscriptions
    case scripts, logs, backup
    case preferences, about

    var id: String { rawValue }
    var title: String { /* ... */ }
    var systemImage: String { /* SF Symbol */ }
    var group: SidebarGroup { /* .apps / .subscribe / .tools / .system */ }
}
```

### 菜单命令

| 菜单            | 项                   | 快捷键 | 动作                                 |
|-----------------|----------------------|--------|--------------------------------------|
| Relay (App)     | Settings…            | ⌘,     | 切换 sidebar 到 `.preferences`       |
|                 | About Relay          | -      | 弹出 About 面板                      |
| File            | Import Backup…       | ⇧⌘I    | NSOpenPanel → `impGlobalBak`         |
|                 | Export Backup…       | ⇧⌘E    | NSSavePanel → 导出 JSON              |
|                 | New Window           | ⌘N     | 新开一个 WindowGroup 实例（可选）    |
| Edit            | (标准 Cut/Copy/Paste)| -      | 系统默认                             |
| View            | Show/Hide Sidebar    | ⌥⌘S    | `toggleSidebar`                      |
| Data            | Refresh              | ⌘R     | `BoxJsViewModel.fetchData()`         |
| Help            | GitHub Repo          | -      | `NSWorkspace.open(...)`              |

### 工具栏（窗口右上角）

- **Primary ToolbarItem**（动态）：根据 sidebar 选中项切换，例如 home 上显示「刷新」「添加应用」。
- **Secondary**：状态指示（已连接 BoxJS / 未配置）、搜索字段（全局搜索）。

---

## 组件和接口

### 1. `RelayMacApp`

**职责**：App 入口、命令菜单定义、全局 EnvironmentObject 注入。

```swift
@main
struct RelayMacApp: App {
    @StateObject private var toastManager = ToastManager()
    @StateObject private var boxModel = BoxJsViewModel()
    @StateObject private var apiManager = ApiManager.shared

    var body: some Scene {
        WindowGroup("Relay") {
            MainWindowView()
                .environmentObject(apiManager)
                .environmentObject(toastManager)
                .environmentObject(boxModel)
                .frame(minWidth: 900, minHeight: 560)
                .onAppear { /* fetchData if configured */ }
                .onOpenURL(perform: handleURL)
        }
        .windowStyle(.hiddenTitleBar)   // 让工具栏和标题栏融合（Liquid Glass 风）
        .windowResizability(.contentSize)
        .commands {
            RelayMenuCommands(/* ... */)
        }

        Settings {  // 替代「Settings…」原生面板（可选）
            MacPreferencesView()
                .environmentObject(apiManager)
        }
    }
}
```

### 2. `MainWindowView`

```swift
struct MainWindowView: View {
    @State private var selection: SidebarItem = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @EnvironmentObject var apiManager: ApiManager

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            DetailRouter(selection: selection)
        }
        .toolbar { MainToolbar(selection: selection) }
        .sheet(isPresented: .constant(!apiManager.isApiUrlSet())) {
            MacOnboardingSheet()
        }
        .overlay(alignment: .bottom) {
            MacToast()
        }
    }
}
```

### 3. `SidebarView`

```swift
struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(selection: $selection) {
            Section("应用") {
                Label("收藏", systemImage: "star").tag(SidebarItem.home)
                Label("搜索", systemImage: "magnifyingglass").tag(SidebarItem.search)
            }
            Section("订阅") {
                Label("订阅源", systemImage: "rectangle.stack").tag(SidebarItem.subscriptions)
            }
            Section("工具") {
                Label("脚本编辑器", systemImage: "curlybraces").tag(SidebarItem.scripts)
                Label("日志", systemImage: "doc.text.magnifyingglass").tag(SidebarItem.logs)
                Label("备份", systemImage: "externaldrive").tag(SidebarItem.backup)
            }
            Section("系统") {
                Label("偏好设置", systemImage: "gear").tag(SidebarItem.preferences)
                Label("关于", systemImage: "info.circle").tag(SidebarItem.about)
            }
        }
        .listStyle(.sidebar)
        // macOS 26 的 .sidebar 样式已经自带 Liquid Glass 材质
    }
}
```

### 4. `PlatformBridge`（共享抽象）

```swift
// Helpers/PlatformBridge.swift（Target: iOS + macOS 双勾）
import SwiftUI

enum PlatformBridge {
    static func copyToPasteboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    static func open(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }

    static func haptic(_ style: HapticStyle = .medium) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: style.uiStyle).impactOccurred()
        #else
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        #endif
    }

    enum HapticStyle { case light, medium, heavy
        #if os(iOS)
        var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle { /* map */ .medium }
        #endif
    }
}
```

### 5. `MacAppDetailView`（示例）

```swift
struct MacAppDetailView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    let appModel: AppModel

    @State private var draftSettings: [String: AnyCodable] = [:]

    var body: some View {
        Form {
            Section("基础") {
                LabeledContent("名称", value: appModel.name)
                LabeledContent("作者", value: appModel.author ?? "-")
            }
            Section("设置") {
                ForEach(appModel.settings) { setting in
                    SettingRowMac(setting: setting, value: Binding(
                        get: { draftSettings[setting.id] ?? .init("") },
                        set: { draftSettings[setting.id] = $0 }
                    ))
                }
            }
            Section("会话") {
                ForEach(appModel.sessions) { session in
                    SessionRowMac(session: session)
                }
            }
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("保存", action: save).buttonStyle(.glass)
            }
        }
        .navigationTitle(appModel.name)
        .navigationSubtitle(appModel.author ?? "")
    }

    private func save() {
        Task {
            let result = await boxModel.updateDataAsync(/* ... */)
            // 通过 ToastManager 提示结果
        }
    }
}
```

---

## 数据模型

**全部复用** `Relay/Models/BoxDataModel.swift`。新增小型辅助类型（仅 macOS）：

```swift
// RelayMac/Views/RootWindow/SidebarItem.swift
enum SidebarItem: String, Hashable, CaseIterable, Identifiable { /* 见上文 */ }

// RelayMac/Views/RootWindow/DetailRouter.swift
struct DetailRouter: View {
    let selection: SidebarItem
    var body: some View {
        switch selection {
        case .home: MacHomeView()
        case .search: MacSearchView()
        case .subscriptions: MacSubscribeListView()
        case .scripts: MacScriptEditorView()
        case .logs: MacLogViewerView()
        case .backup: MacBackupView()
        case .preferences: MacPreferencesView()
        case .about: MacAboutView()
        }
    }
}
```

---

## 错误处理

| 错误类型              | 处理方式                                                    |
|-----------------------|-------------------------------------------------------------|
| 网络请求失败          | 复用 `BoxJsViewModel` 的 `ToastManager` → macOS 底部玻璃 Toast |
| BoxJS 未配置          | `MacOnboardingSheet` 弹出引导配置（阻塞式 sheet）            |
| 备份 JSON 解析失败    | NSAlert 或 Toast 提示 "文件格式错误"                         |
| URL scheme 参数缺失   | Toast 提示「缺少订阅地址」等                                 |
| 保存设置失败          | Toast + 保留未保存草稿，不自动关闭窗口                       |
| Liquid Glass API 不可用（Beta SDK）| `#if canImport(...)` 加 `Material.ultraThinMaterial` 回退 |

---

## 测试策略

项目当前**没有测试 target**。本次设计**不新增 XCTest target**，但定义人工验证清单：

### 人工冒烟测试（SC-3 的落地）

| 步骤 | 动作                                                         | 期望结果                                   |
|------|--------------------------------------------------------------|--------------------------------------------|
| 1    | 运行 `RelayMac` scheme                                       | 窗口启动，弹出 Onboarding Sheet            |
| 2    | 输入 BoxJS 服务器地址并保存                                  | Sheet 关闭，侧边栏显示数据                 |
| 3    | 点击侧边栏「收藏」                                           | 右侧显示应用网格（Liquid Glass 卡片）      |
| 4    | 双击某个应用                                                 | 进入 `MacAppDetailView`，Form 显示设置     |
| 5    | 修改某项设置 → ⌘S                                            | Toast 提示保存成功，数据写回服务器         |
| 6    | ⌘, 打开偏好                                                  | Settings 面板弹出                          |
| 7    | File → Import Backup… 选择 JSON                              | 导入成功，Toast 提示                       |
| 8    | 在终端执行 `open "relay://import?url=https://..."`           | macOS 窗口被激活，订阅被添加               |
| 9    | 构建 iOS scheme                                              | 构建成功，iOS 功能无回归                   |

### 构建验证

- `xcodebuild -scheme Relay` → iOS 构建必须成功
- `xcodebuild -scheme RelayMac -destination 'platform=macOS'` → macOS 构建必须成功

---

## 风险与缓解

| 风险                                     | 影响 | 缓解                                                       |
|------------------------------------------|------|------------------------------------------------------------|
| Liquid Glass API 在 Beta macOS 26 行为变化 | 中   | 优先用 Material 系标准 API，`.glassEffect()` 作为增强而非必需 |
| 共享代码抽象不足导致 `#if os` 扩散       | 中   | 只对确认需要的点做抽象（Pasteboard / URL / Haptic），其它不动 |
| Xcode 项目文件冲突                       | 高   | 一次性新增 target 和所有目录，避免反复改 pbxproj           |
| AvatarStorage 里的 UIImage 依赖          | 低   | 引入 `PlatformImage` typealias，或在 macOS 端单独实现      |
| 首次实现范围失控                         | 高   | 通过 tasks.md 拆分原子任务，先跑通最小可用窗口再迭代       |
