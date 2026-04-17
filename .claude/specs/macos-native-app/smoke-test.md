# Relay macOS 原生应用 - 冒烟测试清单

> 根据 `design.md` 的 9 步人工验证，运行前需在 Xcode 中切换 scheme 至 `RelayMac`，destination 选 "My Mac"。

## 构建验证（自动化）

- [x] `xcodebuild -scheme Relay` → iOS 构建成功（已验证）
- [x] `xcodebuild -scheme RelayMac -destination 'platform=macOS'` → macOS 构建成功（已验证）

## 9 步功能验证（需用户手动运行 RelayMac）

| 步骤 | 动作                                                       | 期望结果                                             | 状态  |
|------|------------------------------------------------------------|------------------------------------------------------|-------|
| 1    | 运行 RelayMac scheme                                       | 窗口启动，显示 Onboarding Sheet                      | 待验证 |
| 2    | 输入 BoxJS 服务器地址并点击「保存并继续」                   | Sheet 关闭，侧边栏可见                               | 待验证 |
| 3    | 点击侧边栏「收藏应用」                                      | 网格展示收藏应用卡片（Liquid Glass 卡片 + hover 反馈）| 待验证 |
| 4    | 双击某个应用（或点击卡片）                                  | Sheet 弹出 `MacAppDetailView`，显示 Form 表单        | 待验证 |
| 5    | 修改某项设置 → ⌘S（或工具栏「保存」）                       | Toast 提示「已提交」，Sheet 关闭                     | 待验证 |
| 6    | 顶部菜单「Relay → Settings…」或 ⌘,                         | macOS Settings 面板弹出，显示 `MacPreferencesView`    | 待验证 |
| 7    | 菜单「数据 → 导入备份…」或 ⇧⌘I                             | NSOpenPanel 打开，选 JSON 后 Toast 提示导入成功      | 待验证 |
| 8    | 终端执行 `open "relay://import?url=https://example.com/sub.json"` | RelayMac 被激活，订阅被添加                          | 待验证 |
| 9    | 切回 `Relay` scheme，选 iPhone 模拟器并构建               | 构建成功，iOS 功能无回归                             | 待验证 |

## 构建工件信息

- **macOS SDK**: macOS 26.4 (Xcode 26)
- **Deployment Target**: macOS 26.3
- **Bundle ID**: `net.sodion.RelayMac`
- **App Sandbox**: 启用（network.client + user-selected files + downloads read-write）
- **Hardened Runtime**: 启用
- **URL Scheme**: `relay://` 注册在 Info.plist
- **Info.plist 模式**: GENERATE_INFOPLIST_FILE = YES（Xcode 自动生成 + 手动 Info.plist 文件备用）

## 已知限制（本次范围外）

- ❌ Mac Catalyst（未使用，采用原生 AppKit + SwiftUI）
- ❌ MenuBarExtra 常驻
- ❌ 多窗口场景 / 多文档模型
- ❌ iCloud 同步 iOS ↔ macOS
- ❌ 脚本编辑器的实际执行（仅提供文本编辑/复制）
- ❌ ScriptEditorView 的服务器端运行（需要进一步对接 NetworkProvider.runScript）
- ❌ 应用详情内的 Session 管理（仅基础 Form）
- ❌ ViewModifier.swift 和 Vibration.swift 仍为 iOS-only（macOS 通过 PlatformBridge.haptic 处理触觉）

## 已引入的共享层变动

| 文件                            | 类型    | 说明                                          |
|---------------------------------|---------|-----------------------------------------------|
| `Relay/Helpers/PlatformBridge.swift` | 新增    | Pasteboard / URL / Haptic 跨平台抽象          |
| `Relay/Helpers/PlatformColors.swift` | 新增    | 6 个跨平台语义色（`relaySystemGroupedBackground` 等） |
| `Relay/Helpers/PlatformImage.swift`  | 新增    | `PlatformImage` typealias + JPEG/PNG 跨平台序列化 |
| `Relay/Managers/LogManager.swift`    | 修改    | UIKit import 改为条件编译，macOS 用 ProcessInfo |
| `Relay/Helpers/Utils.swift`          | 修改    | `openInSafari`/`copyToClipboard` 改用 PlatformBridge；`showTextFieldAlert` 用 `#if os(iOS)` 守卫 |
| `Relay/Helpers/AvatarStorage.swift`  | 修改    | `UIImage` 改为 `PlatformImage` |

这些修改确保 iOS Relay target 行为不变，同时让共享代码能编进 RelayMac target。

## 新增文件清单（RelayMac/）

```
RelayMac/
├── Info.plist
├── RelayMac.entitlements
├── RelayMacApp.swift
├── Assets.xcassets/                  (由 Xcode 生成)
├── Views/
│   ├── RootWindow/
│   │   ├── SidebarItem.swift
│   │   ├── SidebarView.swift
│   │   ├── DetailRouter.swift
│   │   ├── MainWindowView.swift
│   │   └── RelayMenuCommands.swift
│   ├── Onboarding/
│   │   └── MacOnboardingSheet.swift
│   ├── Home/
│   │   └── MacHomeView.swift
│   ├── Subscribe/
│   │   ├── MacSubscribeListView.swift
│   │   └── MacSubscribeDetailView.swift
│   ├── AppDetail/
│   │   ├── MacAppDetailView.swift
│   │   └── SettingRowMac.swift
│   ├── Preferences/
│   │   └── MacPreferencesView.swift
│   ├── Logs/
│   │   └── MacLogViewerView.swift
│   ├── Backup/
│   │   └── MacBackupView.swift
│   ├── Script/
│   │   └── MacScriptEditorView.swift
│   ├── About/
│   │   └── MacAboutView.swift
│   └── Components/
│       ├── GlassAppCard.swift
│       └── MacToast.swift
└── Platform/                         (预留目录，当前未用)
```
