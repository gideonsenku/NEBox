# Relay macOS 原生应用 - 更改文档

## 更改概述

**版本**: 2026-04-18
**任务**: 为 Relay 项目新增独立 macOS target（最低 macOS 26.0），采用 Liquid Glass 设计，与 iOS target 共存于同一 Xcode 项目

本次变更在现有 iOS SwiftUI 客户端旁新增完整的原生 macOS 应用，不使用 Mac Catalyst，iOS Views 全部重写。Models/ViewModels/Services/Managers 通过 Target Membership 共享。

---

## 新增 Target

### `RelayMac` (macOS 26.0+)

- Bundle ID: `net.sodion.RelayMac`
- SDK: macOS 26.4
- Deployment Target: macOS 26.3
- App Sandbox + Hardened Runtime
- Entitlements: network.client + files.user-selected.read-write + files.downloads.read-write
- URL Scheme: `relay://`
- 文档类型: `public.json`

---

## 新增文件

### macOS 专属源码 (`RelayMac/`)

| 文件 | 用途 | 关键接口 |
|------|------|---------|
| `RelayMacApp.swift` | App 入口 | `@main App`, `handleDeepLink`, `handleIncomingFile` |
| `Info.plist` | ATS + URL scheme + 文档类型 | - |
| `RelayMac.entitlements` | 沙箱权限 | - |
| `Views/RootWindow/SidebarItem.swift` | 侧边栏枚举 (7 项 × 3 组) | `SidebarItem.home/subscriptions/…` |
| `Views/RootWindow/SidebarView.swift` | 侧边栏 List (native `.sidebar` 样式) | - |
| `Views/RootWindow/DetailRouter.swift` | 侧边栏选项 → 详情视图路由 | `DetailRouter(selection:)` |
| `Views/RootWindow/MainWindowView.swift` | NavigationSplitView 根容器 + 工具栏 + 沙箱 Sheet | - |
| `Views/RootWindow/RelayMenuCommands.swift` | 菜单命令 (⌘R 刷新、⇧⌘I 导入、Help → 项目主页) | `RelayMenuCommands` |
| `Views/Onboarding/MacOnboardingSheet.swift` | 首次启动地址配置 | - |
| `Views/Home/MacHomeView.swift` | 收藏应用 LazyVGrid | - |
| `Views/Subscribe/MacSubscribeListView.swift` | 订阅源双栏 List/Detail | - |
| `Views/Subscribe/MacSubscribeDetailView.swift` | 单订阅下的应用网格 | - |
| `Views/AppDetail/MacAppDetailView.swift` | 应用设置 Form + 保存 | - |
| `Views/AppDetail/SettingRowMac.swift` | 单行设置（Toggle/Picker/TextField） | - |
| `Views/Preferences/MacPreferencesView.swift` | 偏好设置 (改用 macOS `Settings` scene) | - |
| `Views/Logs/MacLogViewerView.swift` | 日志查看（过滤、复制、清空） | - |
| `Views/Backup/MacBackupView.swift` | 备份 Import/Export (NSOpenPanel/NSSavePanel) | - |
| `Views/Script/MacScriptEditorView.swift` | 脚本文本编辑器 | - |
| `Views/About/MacAboutView.swift` | 关于页面 | - |
| `Views/Components/GlassAppCard.swift` | 玻璃应用卡片 + hover 反馈 | - |
| `Views/Components/MacToast.swift` | 底部玻璃 Toast | - |

### 共享跨平台抽象 (`Relay/Helpers/`)

| 文件 | 用途 | 关键接口 |
|------|------|---------|
| `PlatformBridge.swift` | Pasteboard / URL / Haptic 跨平台封装 | `PlatformBridge.copyToPasteboard`, `.open`, `.impact`, `.notify`, `.resignFirstResponder` |
| `PlatformColors.swift` | 6 个语义色跨平台别名 | `Color.relaySystemGroupedBackground` 等 |
| `PlatformImage.swift` | `UIImage` / `NSImage` 统一 typealias + JPEG/PNG 序列化 | `PlatformImage`, `jpegRepresentation`, `pngRepresentation`, `Image(platformImage:)` |

---

## 修改文件

| 文件 | 更改 | 原因 |
|------|------|------|
| `Relay/Managers/LogManager.swift` | `import UIKit` → `#if os(iOS) import UIKit #endif`；startup banner 使用 `ProcessInfo` fallback | 让共享到 RelayMac target 时能编译 |
| `Relay/Helpers/Utils.swift` | `openInSafari` / `copyToClipboard` 改用 `PlatformBridge`；`showTextFieldAlert` 用 `#if os(iOS)` 守卫 | 消除共享代码里的 UIKit 硬依赖 |
| `Relay/Helpers/AvatarStorage.swift` | `UIImage` → `PlatformImage`；PNG 序列化用 `pngRepresentation()` | 支持 macOS NSImage |
| `Relay.xcodeproj/project.pbxproj` | 新增 RelayMac target + Sources build phase + Frameworks + 10 个共享文件 + 3 个 Platform* 抽象 + 3 个 Helper (Utils/AvatarStorage/GlobalToastView) Target Membership；移除 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`；启用 manual Info.plist + entitlements | 建立 macOS target，避免 Swift 6 并发隔离与共享 Services 冲突；关键修复：让手写 Info.plist 生效（ATS + URL scheme） |

---

## 架构决策

1. **独立 target，非 Catalyst**：保留 macOS 原生外观，自由使用 Liquid Glass，不被 iPad 样式污染
2. **文件系统同步组**：`RelayMac/` 使用 Xcode 16+ 的 `PBXFileSystemSynchronizedRootGroup`，新增文件自动加入 target，无需手改 pbxproj
3. **Target Membership 复用**：Models/ViewModels/Services/Managers 通过双勾实现单一实现跨平台
4. **最小抽象**：只抽象必要的（Pasteboard/URL/Haptic/Image/Colors），避免过度设计
5. **Liquid Glass 防御性**：`GlassAppCard` 和 `MacToast` 用 `@available(macOS 26.0, *)` 检查 `.glassEffect()`，回退 `.regularMaterial`
6. **禁用 Swift 6 默认 MainActor 隔离**：与 iOS target 行为对齐，避免共享 Services 层的 async/await 代码触发 isolation 错误

---

## Codex 审查（2026-04-18）

| 严重性 | 问题 | 修复 |
|--------|------|------|
| 🔴 阻断 | `MainWindowView` 弹出 `MacOnboardingSheet` 时未注入 `boxModel` EnvironmentObject，导致 Sheet 内部崩溃 | 添加 `.environmentObject(boxModel)` |
| 🟡 建议 | `handleIncomingFile` 导入完成无条件显示"导入成功" toast 会覆盖 ViewModel 的错误 toast | 移除冗余 toast，依赖 ViewModel 内部提示 |
| 🟡 建议 | `MacAppDetailView.save()` fire-and-forget，无网络失败处理 | 保留（对齐 iOS 行为） |
| 🟢 小优化 | `LogManager.readLogs()` 与 writer 队列不一致，可能读到截断行 | 保留（低风险） |

---

## 运行时根因修复

初次本地运行报告"无数据" — 定位为 Xcode 默认 `GENERATE_INFOPLIST_FILE = YES` 导致手写 Info.plist 和 entitlements 被忽略：
- ATS 未关闭 → HTTP BoxJS 服务器被阻止
- `relay://` URL scheme 未注册
- `com.apple.security.network.client` entitlement 未启用

修复方案：pbxproj 改为 `GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = RelayMac/Info.plist` + `CODE_SIGN_ENTITLEMENTS = RelayMac/RelayMac.entitlements`。验证后 built app 的 `Info.plist` 正确包含 `NSAppTransportSecurity.NSAllowsArbitraryLoads = true` 和 `CFBundleURLTypes = [relay]`，entitlements 包含 `com.apple.security.network.client`。

---

## 使用示例

启动后：

1. 首次启动 → Onboarding Sheet → 填写 BoxJS 地址 (如 `http://127.0.0.1:9909/box/`) → 保存
2. 侧边栏「收藏应用」→ 玻璃卡片网格 → 点击卡片 → 设置 Form
3. 侧边栏「订阅源」→ 左侧 List + 右侧应用网格
4. 菜单「数据 → 导入备份…」(⇧⌘I) → NSOpenPanel 选 JSON → ViewModel 自动导入
5. `⌘R` 全局刷新；`⌘,` 偏好设置 (macOS Settings scene)

外部触发：
```bash
open "relay://import?url=https://example.com/sub.json"
```

---

## 已知限制与后续工作

- ❌ Mac Catalyst：未采用，本次用原生 AppKit + SwiftUI
- ❌ MenuBarExtra 常驻
- ❌ 多窗口 / 多文档
- ❌ iCloud 同步
- ❌ 脚本编辑器的实际运行（仅提供文本编辑/复制）
- ❌ 应用详情 Session 管理（仅基础 Form）
- ⚠️ `ViewModifier.swift` 与 `Vibration.swift` 仍为 iOS-only（macOS 通过 `PlatformBridge.impact` 处理触觉；如需共用 `Color(hex:)` 可后续单独抽出）

---

## 依赖变更

SPM 依赖无新增，仅在 RelayMac target 的 Frameworks 里链接了已有的 Moya / Alamofire / AnyCodable / SDWebImageSwiftUI。

🤖 Generated with Nexus CLI
