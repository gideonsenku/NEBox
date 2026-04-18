# RelayMac Dark Mode 适配 - 需求文档

## 功能概述

当前 RelayMac 目标（macOS 26+ Liquid Glass 原生应用）在 Dark Mode 下显示异常：
- `SidebarView.swift:87` 显式将侧边栏 `colorScheme` 强制为 `.light`
- 全应用 27+ 处硬编码 `Color.white` / `Color.black` / `Color(red:...)` RGB 字面量
- `WorkbenchWindowBackground` 为纯浅色渐变，无 dark 分支
- `AccentColor.colorset` 无 Dark appearance 变体

本次工作让 RelayMac 在系统 Dark Mode 下自然切换，并保持用户 memory 中记录的"Mac Native Materials, Not Simulated Glass"原则——用 stock Materials 和 `Color(nsColor:)` 语义色，而不是手工构造两套渐变/边框。

---

## 需求列表

### REQ-1: 系统外观跟随

**用户故事**: 作为 RelayMac 用户，我切换 macOS 的外观为 Dark Mode 时，RelayMac 应整体同步切换，不留下任何"浅色孤岛"。

**验收标准 (EARS 格式)**:

1. **REQ-1.1** [State-driven]: 当系统外观为 Dark 时，RelayMac 所有窗口背景、卡片、输入区、侧边栏、编辑器、Toast、Onboarding Sheet **应当**显示为深色样式。
2. **REQ-1.2** [Ubiquitous]: RelayMac **不应当**在任何视图层级强制 `.environment(\.colorScheme, .light)` 或 `.preferredColorScheme(.light)`。
3. **REQ-1.3** [Event-driven]: 当用户在系统设置中切换 Light/Dark 时，RelayMac 应立即响应变化（SwiftUI 原生行为，无需重启）。
4. **REQ-1.4** [Unwanted behavior]: Dark Mode 下**不应当**出现高亮刺眼的纯白面板、黑色文本显示在深色底上的可读性问题。

### REQ-2: 原生 Materials 优先

**用户故事**: 作为项目维护者，我希望 Dark Mode 适配坚持"使用 stock Materials 和原生 macOS 色，不手工模拟玻璃"的原则，避免产生两套硬编码色板需要同步维护。

**验收标准 (EARS 格式)**:

1. **REQ-2.1** [Ubiquitous]: 卡片/面板背景**应当**优先使用 `.regularMaterial` / `.thinMaterial` / `.ultraThinMaterial`，或 `Color(nsColor: .controlBackgroundColor)` / `Color(nsColor: .textBackgroundColor)` / `Color(nsColor: .windowBackgroundColor)` 等语义色。
2. **REQ-2.2** [Ubiquitous]: 边框/分隔线**应当**使用 `Color(nsColor: .separatorColor)` 或 `Color.primary.opacity(...)`。
3. **REQ-2.3** [Unwanted behavior]: **不应当**为同一个视觉元素写两套硬编码 RGB 分别对应 light/dark。
4. **REQ-2.4** [Optional]: 如果某处确需品牌色或特殊色，**可以**在 `Assets.xcassets` 中添加 Any/Dark 两套变体，由系统自动切换。

### REQ-3: 共享组件集中修复

**用户故事**: 作为开发者，我希望修复集中在共享组件（`WorkbenchSurfaces`、`MainWindowView` 的 detail card、编辑器/日志面板的重复卡片样式），一次修复覆盖多个屏幕，而不是每个屏幕各改一遍。

**验收标准 (EARS 格式)**:

1. **REQ-3.1** [Ubiquitous]: `WorkbenchSurfaces.swift` 的 `WorkbenchWindowBackground` **应当**改造为系统外观自适应（通过 Material 或系统色）。
2. **REQ-3.2** [Ubiquitous]: `MainWindowView.swift` 中的 detail card 背景（当前 `Color.white.opacity(0.92)` + 硬阴影）**应当**替换为 Material 方案，一处修改覆盖所有子屏幕。
3. **REQ-3.3** [Optional]: **可以**在 `WorkbenchSurfaces.swift` 中新增共享 `WorkbenchPanelBackground` / `WorkbenchSubtleFill` view modifier，用于替换 `MacLogViewerView` / `MacScriptEditorView` / `MacDataViewerView` / `MacBackupView` / `MacPreferencesView` 中重复的 `Color.white.opacity(0.5)` 等 pattern。

### REQ-4: 视觉一致性与可读性

**用户故事**: 作为用户，我希望 Dark Mode 下的 RelayMac 在对比度、层次感、图标可读性上与 Light Mode 保持同等体验。

**验收标准 (EARS 格式)**:

1. **REQ-4.1** [Ubiquitous]: 所有文本**应当**使用 `.primary` / `.secondary` 语义色，而非硬编码 `Color.white` 或 `Color.black`（按钮 primary 文本除外，见 REQ-4.3）。
2. **REQ-4.2** [State-driven]: 状态色（`.green` / `.orange` / `.red` / `.accentColor`）在 Dark Mode 下应保持可识别——使用 SwiftUI 内置 `.green` / `.orange` / `.red` 即自动适配。
3. **REQ-4.3** [Unwanted behavior]: "Primary action" 按钮上的前景色为 `Color.white` 是合理的（背景是 `.accentColor`），**不应当**被错误替换为 `.primary`。
4. **REQ-4.4** [Ubiquitous]: 代码编辑器 / 日志查看器的"纸面"背景**应当**使用 `Color(nsColor: .textBackgroundColor)`，字体色用 `Color(nsColor: .labelColor)`（目前 `MacJavaScriptCodeEditor` 已经是对的，保持即可）。

---

## 边缘情况

1. **EC-1**: **Onboarding Sheet** 的欢迎背景若使用自定义渐变/图片 - 需要检查并替换为原生外观或加 dark 变体。
2. **EC-2**: **GlassAppCard** 已使用 `.glassEffect()` + `.thinMaterial`，但 `line 80` 有 `.strokeBorder(Color.white.opacity(...))` 的 inner stroke——Dark 下这个 `Color.white` 高光可能需要保留（玻璃高光语义），在 review 时确认。
3. **EC-3**: **AccentColor 无 Dark 变体** - 检查项目当前 AccentColor 是否需要 dark 下调整亮度，如不需要则保留；如需要则在 Assets 中添加变体。
4. **EC-4**: **Toast** 使用 `.regularMaterial` 已是正确做法，但如有残留硬编码文本色需清理。
5. **EC-5**: **Preferences 状态徽章**（绿/红/橙）使用 `.opacity(0.1)` 作为底色底图——SwiftUI 的 `.green.opacity(0.1)` 在 dark 下会变暗，通常可接受，但需目测验证。

---

## 技术约束

1. **TC-1**: 目标 macOS 版本为 macOS 26+，可自由使用 `.glassEffect()` / Materials / 最新 SwiftUI API。
2. **TC-2**: 禁止修改 iOS `Relay` target 的任何文件——本次工作只涉及 `RelayMac/` 目录。
3. **TC-3**: 遵循 user memory "Mac Native Materials, Not Simulated Glass"——禁止为 dark 额外写 gradient / border / shadow 来模拟玻璃。
4. **TC-4**: 无现有测试 target，验证方式为构建通过 + 人工 light/dark 切换检查。

---

## 成功标准

1. **SC-1**: `xcodebuild` 构建 RelayMac scheme 成功，无新增 warning。
2. **SC-2**: 代码中 `grep -n 'Color\.white\|Color\.black\|Color(red:'` 在 `RelayMac/` 目录下剩余项均为合理场景（按钮 primary 文本、玻璃高光、状态指示圆点等），每一个剩余项在 design.md 中被明确列为"预期保留"。
3. **SC-3**: `SidebarView.swift` 中 `.environment(\.colorScheme, .light)` 已移除。
4. **SC-4**: 人工在系统 Appearance 里切换 Light / Dark，RelayMac 所有主要屏幕（Home / AppDetail / Script / Data / Logs / Backup / Subscribe / Search / Preferences / Onboarding）视觉一致、可读、无浅色孤岛。
