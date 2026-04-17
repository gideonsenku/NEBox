# Relay macOS 原生应用 - 实施任务清单

## 概述

按依赖关系分为 **7 个批次**，共 **27 个原子任务**。批次 1 必须先完成（Xcode 项目配置），其余批次可大量并行。CLAUDE_ONLY_MODE 下所有任务由 Claude 执行器处理。

---

## ⚠️ 关键前置风险：Xcode 项目文件修改

**`Relay.xcodeproj/project.pbxproj` 是 Xcode 维护的关键文件**，手工编辑容易损坏。**批次 1 的 Target 创建任务最稳妥方案是用户在 Xcode 中手动执行**（File → New → Target → macOS App），Claude 负责：
- 给出精确的 Xcode 操作步骤清单
- 在用户完成后验证 pbxproj 修改并补充 Target Membership、deployment target 等细节
- 准备所有源码文件（RelayMac/ 目录）等待 Xcode 引用

批次 2 及之后的任务不涉及 pbxproj 结构性改动，均可自动执行。

---

## 批次 1: Xcode 项目 Target 配置（串行，需要用户协作）

| ID  | 任务                                                                       | 执行器 | 预估 | 依赖 | 输出文件                                       |
|-----|-----------------------------------------------------------------------------|--------|------|------|------------------------------------------------|
| 1.1 | 撰写 Xcode target 创建操作指南（给用户的手动步骤清单）                     | Claude | 3min | -    | `.claude/specs/macos-native-app/xcode-setup.md` |
| 1.2 | 创建 macOS target 目录骨架（空目录 + README 占位）                         | Claude | 2min | -    | `RelayMac/` 目录结构                            |
| 1.3 | 生成 `RelayMac/Info.plist`（URL scheme、NSAllowsArbitraryLoads）            | Claude | 3min | 1.2  | `RelayMac/Info.plist`                           |
| 1.4 | 生成 `RelayMac/RelayMac.entitlements`（沙箱 + 网络 + 文件权限）              | Claude | 3min | 1.2  | `RelayMac/RelayMac.entitlements`                |
| 1.5 | **（用户）** 在 Xcode 新建 macOS App target `RelayMac`，最低版本 26.0，SwiftUI，选中 Info.plist/entitlements | 用户   | 5min | 1.1-1.4 | Xcode 项目中新 target                          |
| 1.6 | 验证 pbxproj，补齐 SPM 依赖（Moya/Alamofire/AnyCodable/SDWebImageSwiftUI）到 RelayMac target | Claude | 5min | 1.5  | 更新 `project.pbxproj`                          |

**批次完成标准**：Xcode 中存在 `Relay`（iOS）和 `RelayMac`（macOS）两个 scheme，两个 scheme 均可被选中；`xcodebuild -list` 显示两个 target。

---

## 批次 2: 共享层跨平台抽象（并行）

目标：将共享代码中直接调用 UIKit 的点抽象为平台中立接口。iOS target 继续正常工作，macOS target 编译无缺失符号。

| ID  | 任务                                                                                 | 执行器 | 预估 | 依赖 | 输出文件                                       |
|-----|---------------------------------------------------------------------------------------|--------|------|------|------------------------------------------------|
| 2.1 | 创建 `Relay/Helpers/PlatformBridge.swift`（Pasteboard/URL/Haptic 跨平台封装）         | Claude | 4min | 1.6  | `Relay/Helpers/PlatformBridge.swift`（双 target membership） |
| 2.2 | 创建 `Relay/Helpers/PlatformColors.swift`（跨平台 Color 别名，覆盖 `_systemGroupedBackground` 等 6 个常用色） | Claude | 4min | 1.6  | `Relay/Helpers/PlatformColors.swift`           |
| 2.3 | 创建 `Relay/Helpers/PlatformImage.swift`（`PlatformImage` typealias + `Image(platformImage:)`） | Claude | 3min | 1.6  | `Relay/Helpers/PlatformImage.swift`            |
| 2.4 | 审查 `Relay/Extension/ViewModifier.swift`，将 UIKit 相关 modifier 用 `#if os(iOS)` 包裹 | Claude | 4min | 1.6  | 更新 `ViewModifier.swift`                      |
| 2.5 | 审查 `Relay/Helpers/AvatarStorage.swift`，改用 `PlatformImage`，UIImage/NSImage 条件处理 | Claude | 4min | 2.3  | 更新 `AvatarStorage.swift`                     |
| 2.6 | 审查 `Relay/Helpers/Utils.swift`，用 `#if os(iOS)` 包裹 `showTextFieldAlert`            | Claude | 3min | 1.6  | 更新 `Utils.swift`                             |
| 2.7 | 审查 `Relay/Helpers/Vibration.swift`，保持仅 iOS（macOS 端通过 PlatformBridge.haptic）  | Claude | 2min | 2.1  | 更新 `Vibration.swift` 或无改动                |

**批次完成标准**：在仅勾选 macOS target 的情况下，Services/Managers/Models/ViewModels/Helpers 编译无错误（可通过为 RelayMac target 添加这些文件的 Target Membership 并尝试构建验证）。

---

## 批次 3: macOS App 入口与窗口框架（串行依赖，可小并行）

| ID  | 任务                                                                          | 执行器 | 预估 | 依赖 | 输出文件                                      |
|-----|-------------------------------------------------------------------------------|--------|------|------|-----------------------------------------------|
| 3.1 | 创建 `RelayMac/Views/RootWindow/SidebarItem.swift`（枚举 + title/systemImage） | Claude | 3min | 2.*  | `RelayMac/Views/RootWindow/SidebarItem.swift` |
| 3.2 | 创建 `RelayMac/Views/RootWindow/SidebarView.swift`                             | Claude | 5min | 3.1  | `SidebarView.swift`                           |
| 3.3 | 创建 `RelayMac/Views/RootWindow/DetailRouter.swift`（占位路由，各项返回 Text） | Claude | 4min | 3.1  | `DetailRouter.swift`                          |
| 3.4 | 创建 `RelayMac/Views/RootWindow/MainWindowView.swift`                          | Claude | 5min | 3.2, 3.3 | `MainWindowView.swift`                       |
| 3.5 | 创建 `RelayMac/RelayMacApp.swift`（@main + WindowGroup + Settings + 环境对象注入） | Claude | 5min | 3.4  | `RelayMacApp.swift`                           |
| 3.6 | 创建 `RelayMac/Views/RootWindow/RelayMenuCommands.swift`（占位命令组）          | Claude | 4min | 3.5  | `RelayMenuCommands.swift`                     |

**批次完成标准**：RelayMac scheme 可构建成功，启动显示空侧边栏 + 占位 detail（每个条目显示 "MacHomeView 占位" 等 Text）。

---

## 批次 4: 首次启动引导 + Home 视图（并行）

| ID  | 任务                                                                        | 执行器 | 预估 | 依赖 | 输出文件                                                       |
|-----|-----------------------------------------------------------------------------|--------|------|------|----------------------------------------------------------------|
| 4.1 | 创建 `RelayMac/Views/Onboarding/MacOnboardingSheet.swift`（配置 BoxJS 地址表单） | Claude | 5min | 3.5  | `MacOnboardingSheet.swift`                                     |
| 4.2 | 创建 `RelayMac/Views/Home/MacHomeView.swift`（LazyVGrid 收藏应用卡片）        | Claude | 5min | 3.3  | `MacHomeView.swift`                                            |
| 4.3 | 创建 `RelayMac/Views/Components/GlassAppCard.swift`（单个应用卡片，Liquid Glass 样式 + hover） | Claude | 5min | 3.3  | `GlassAppCard.swift`                                           |
| 4.4 | 创建 `RelayMac/Views/Components/MacToast.swift`（底部玻璃 Toast）             | Claude | 4min | 3.4  | `MacToast.swift`                                               |

**批次完成标准**：首次启动弹出 Onboarding Sheet；配置后收藏页显示应用网格，hover 有反馈。

---

## 批次 5: 订阅 + 应用详情（并行）

| ID  | 任务                                                                      | 执行器 | 预估 | 依赖 | 输出文件                                                    |
|-----|---------------------------------------------------------------------------|--------|------|------|-------------------------------------------------------------|
| 5.1 | 创建 `RelayMac/Views/Subscribe/MacSubscribeListView.swift`（双栏 List/Detail） | Claude | 5min | 4.*  | `MacSubscribeListView.swift`                                |
| 5.2 | 创建 `RelayMac/Views/Subscribe/MacSubscribeDetailView.swift`                | Claude | 5min | 5.1  | `MacSubscribeDetailView.swift`                              |
| 5.3 | 创建 `RelayMac/Views/AppDetail/MacAppDetailView.swift`（Form + Section）    | Claude | 5min | 4.*  | `MacAppDetailView.swift`                                    |
| 5.4 | 创建 `RelayMac/Views/AppDetail/SettingRowMac.swift`（单个设置控件：Toggle/TextField/Picker） | Claude | 5min | 5.3  | `SettingRowMac.swift`                                       |
| 5.5 | 创建 `RelayMac/Views/AppDetail/SessionRowMac.swift`                         | Claude | 4min | 5.3  | `SessionRowMac.swift`                                       |

**批次完成标准**：用户可点击收藏里任意应用进入详情 Form；可点击订阅源查看应用列表。

---

## 批次 6: 工具区视图（并行）

| ID  | 任务                                                                            | 执行器 | 预估 | 依赖 | 输出文件                                |
|-----|---------------------------------------------------------------------------------|--------|------|------|-----------------------------------------|
| 6.1 | 创建 `RelayMac/Views/Script/MacScriptEditorView.swift`（TextEditor + 等宽字体） | Claude | 5min | 4.*  | `MacScriptEditorView.swift`             |
| 6.2 | 创建 `RelayMac/Views/Logs/MacLogViewerView.swift`（Table + 搜索 + 级别筛选）   | Claude | 5min | 4.*  | `MacLogViewerView.swift`                |
| 6.3 | 创建 `RelayMac/Views/Backup/MacBackupView.swift`（NSOpenPanel/NSSavePanel + 拖放） | Claude | 5min | 4.*  | `MacBackupView.swift`                   |
| 6.4 | 创建 `RelayMac/Views/Preferences/MacPreferencesView.swift`                      | Claude | 5min | 4.*  | `MacPreferencesView.swift`              |
| 6.5 | 创建 `RelayMac/Views/About/MacAboutView.swift`                                  | Claude | 3min | 4.*  | `MacAboutView.swift`                    |

**批次完成标准**：侧边栏所有条目均可导航到实际视图（不再是占位）。

---

## 批次 7: 命令菜单、工具栏与集成打磨（串行）

| ID  | 任务                                                                        | 执行器 | 预估 | 依赖 | 输出文件                                       |
|-----|-----------------------------------------------------------------------------|--------|------|------|------------------------------------------------|
| 7.1 | 完善 `RelayMenuCommands.swift`（File/Edit/View/Data 菜单，⌘R 刷新、⌘S 保存、⇧⌘I 导入） | Claude | 5min | 6.*  | 更新 `RelayMenuCommands.swift`                 |
| 7.2 | 在 `RelayMacApp` 实现 `handleURL`（relay:// + JSON 文件 onOpenURL）          | Claude | 4min | 7.1  | 更新 `RelayMacApp.swift`                       |
| 7.3 | 完善 `MainWindowView` 工具栏（动态 primary action + 连接状态指示）           | Claude | 5min | 7.1  | 更新 `MainWindowView.swift`                    |
| 7.4 | 运行 iOS + macOS 双构建并修复编译错误                                       | Claude | 5min | 7.3  | 构建日志                                        |
| 7.5 | 人工冒烟清单校对：根据 design.md §测试策略 9 步逐项核验并记录结果            | Claude | 5min | 7.4  | `.claude/specs/macos-native-app/smoke-test.md` |

**批次完成标准**：iOS scheme + RelayMac scheme 均构建成功；冒烟清单记录在 smoke-test.md。

---

## 执行策略

### 批次执行顺序

```
批次 1 [串行 + 用户] → 批次 2 [并行 7 任务]
                    → 批次 3 [小并行] → 批次 4 [并行 4 任务]
                                    → 批次 5 [并行 5 任务]
                                    → 批次 6 [并行 5 任务]
                                    → 批次 7 [串行 5 任务]
```

### 并行度说明

| 批次 | 任务数 | 并行度       | 预估实际时间 |
|------|--------|--------------|--------------|
| 批次 1 | 6      | 串行 + 用户  | 20 min       |
| 批次 2 | 7      | 高并行       | 5 min        |
| 批次 3 | 6      | 部分并行     | 15 min       |
| 批次 4 | 4      | 并行         | 5 min        |
| 批次 5 | 5      | 并行         | 5 min        |
| 批次 6 | 5      | 并行         | 5 min        |
| 批次 7 | 5      | 串行（要构建验证） | 25 min |
| **总计** | **38 任务** | -  | **~80 min** |

### 原子任务规则

- 每个任务聚焦**一个文件**或**一个小主题**（单文件的视图、一个抽象的 helper）
- 涉及 Xcode 项目结构的任务合并为批次 1
- 需要依赖其它任务输出的任务显式标注 `依赖`
- 用户操作（1.5）独立标注「用户」执行器

### 执行器映射（CLAUDE_ONLY_MODE）

所有任务由 Claude 执行器通过 Task tool（subagent）处理。视图层任务使用 `general-purpose` 子代理，Xcode 项目任务使用直接 Bash/Read/Write。

### 批次完成标准验证

每批完成后：
1. 立即更新 TodoWrite（FORCE_BATCH_TODOWRITE）
2. 运行批次完成标准里的验证命令（通常是 `xcodebuild -scheme RelayMac build`）
3. 如失败，立即回滚该批次改动并记录问题，不强行推进

---

## 非原子但不得不有的任务说明

部分视图任务（如 MacAppDetailView）可能超过 5 min 限制，因为 Form 内部嵌套的 SettingRowMac 逻辑较复杂。在这些情况下将控件拆分为独立任务（5.4, 5.5），把主 View 本身保持在骨架层面。

## 风险对照（来自 design.md）

| 风险                     | 任务层面的缓解                                        |
|--------------------------|-------------------------------------------------------|
| Xcode 项目文件损坏       | 批次 1.5 由用户操作，Claude 仅做非结构性 pbxproj 补全 |
| Liquid Glass API 不稳    | 任务 4.3 / 其它玻璃效果使用 Material 作回退           |
| 共享抽象不够             | 批次 2 集中处理，后续批次不再碰共享层                 |
| 编译错误累积             | 批次 7.4 强制双 target 构建验证                       |
