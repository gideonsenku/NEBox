# RelayMac 详情页 Toolbar 修复 - 需求文档

## 功能概述

RelayMac 使用 `.windowStyle(.hiddenTitleBar)` 的无标题栏窗口布局，
内容从窗口顶部一直延伸到底部。详情页（MacAppDetailView、MacSubscribeDetailView、
MacBackupDetailView）使用 SwiftUI 原生 `.toolbar { ToolbarItem(placement: .primaryAction) }`
和 `.navigationTitle/.navigationSubtitle` API —— 这些内容在传统 macOS app
里会渲染到 titlebar，但在 hiddenTitleBar 模式下 SwiftUI 把它们渲染到窗口左上
区域（红绿灯按钮旁边），看起来像"toolbar 跑到了侧边上"。

本次任务把三个详情页的 toolbar 和 navigation title 全部替换为：
- 标题/副标题：inline 渲染到页面 content 顶部
- 操作按钮：
  - 对于 detailCard 上下文（MacAppDetailView、MacSubscribeDetailView）：
    用 `WindowChromeModel.setActions` 把按钮渲染到 detailCard 右上角
  - 对于 bare layout 上下文（MacBackupDetailView）：
    直接 inline 渲染在页面内容顶部，与 MacBackupView 的 header 风格一致

---

## 需求列表

### REQ-1: 消除 toolbar 在红绿灯旁渲染的视觉 bug

**用户故事**: 作为 RelayMac 用户，当我进入订阅详情 / App 详情 / 备份详情页时，
页面的操作按钮应该在页面内合理的位置（右上角 action bar 或页面内 inline），
而不是悬浮在窗口左上角红绿灯旁边。

**验收标准 (EARS 格式)**:

1. **REQ-1.1** [Unwanted behavior]: 三个详情页**不应当**使用 SwiftUI 的
   `.toolbar { ToolbarItem(placement: .primaryAction) }` 或
   `.navigationTitle` / `.navigationSubtitle`。
2. **REQ-1.2** [State-driven]: 当详情页被 detailCard 包裹时（MacAppDetailView、
   MacSubscribeDetailView），操作按钮**应当**通过
   `WindowChromeModel.setActions` 渲染到 detailCard 右上角。
3. **REQ-1.3** [State-driven]: 当详情页在 bare layout 中时（MacBackupDetailView），
   操作按钮**应当** inline 渲染在页面内容顶部。
4. **REQ-1.4** [Ubiquitous]: 三个详情页的标题和副标题**应当** inline 渲染
   到页面内容顶部，而不是依赖 `navigationTitle`/`navigationSubtitle`。

### REQ-2: 保留 App 详情页 Save 的键盘快捷键

**用户故事**: 作为用户，我希望在 App 详情页仍能用 `⌘S` 触发保存，不被本次
重构破坏。

**验收标准 (EARS 格式)**:

1. **REQ-2.1** [Event-driven]: 用户在 MacAppDetailView 按下 `Cmd+S` 时，
   系统**应当**触发 save() 与现有 .toolbar 行为等价。
2. **REQ-2.2** [Unwanted behavior]: 键盘快捷键**不应当**在 drafts 为空或
   saving 为 true 时触发。

### REQ-3: 视觉与交互一致性

**用户故事**: 作为用户，我希望三个详情页 inline 化后的外观与 RelayMac 现有
页面（MacHomeView、MacSubscribeListView、MacBackupView）的 header 风格一致
（大号标题 + 次要副标题 + 右侧操作按钮）。

**验收标准 (EARS 格式)**:

1. **REQ-3.1** [Ubiquitous]: detailCard 上下文的详情页**应当**沿用
   chrome.setActions 已有的 pure-icon 渲染（28×28，带 .help tooltip）。
2. **REQ-3.2** [Ubiquitous]: bare layout 详情页的 inline 按钮**应当**使用与
   MacBackupView 一致的 pattern（HStack header + Spacer + 右侧按钮组）。
3. **REQ-3.3** [Optional]: 若 chrome 操作按钮需要保留 keyboardShortcut，
   **可以**在视图中隐藏一个 Button 承载快捷键。

---

## 边缘情况

1. **EC-1**: MacAppDetailView 的 `.toolbar` 里的"更多"菜单是 Menu，迁移到
   chrome 需要 WindowChromeAction 支持 `.menu(items:)`（现有 `WindowChrome.swift`
   已经支持 menu 类型，直接复用）。
2. **EC-2**: MacSubscribeDetailView 当前的 `chrome.clear()` 在 `.onAppear` 里
   — 本任务不需要 chrome actions，所以这个 clear 保持不变。
3. **EC-3**: MacBackupDetailView 用 bare layout，chrome 渲染不生效；
   即使移除 .toolbar 也不能用 chrome.setActions —— 改为 inline 渲染。
4. **EC-4**: 移除 `navigationTitle` 后，macOS 窗口标题栏区域会什么都不显示
   —— 这是可接受的，因为窗口就是 hiddenTitleBar 模式。

---

## 技术约束

1. **TC-1**: 仅修改 `RelayMac/Views/AppDetail/MacAppDetailView.swift`、
   `RelayMac/Views/Subscribe/MacSubscribeDetailView.swift`、
   `RelayMac/Views/Backup/MacBackupDetailView.swift` 以及必要的小范围支持。
2. **TC-2**: 不改 `WindowChrome.swift`（已支持 button + menu 两种 action kind）。
3. **TC-3**: 不改 `MainWindowView.swift` 的 chrome overlay 渲染逻辑。
4. **TC-4**: 保持 Dark Mode 适配：inline header / button 沿用 `.primary`/
   `.secondary` 语义色。

---

## 成功标准

1. **SC-1**: `xcodebuild` RelayMac scheme 构建通过。
2. **SC-2**: 三个详情页不再出现 `.toolbar { ToolbarItem }`、
   `.navigationTitle`、`.navigationSubtitle`（grep 无残留）。
3. **SC-3**: App 详情页 `⌘S` 仍可正常保存。
4. **SC-4**: 人工从订阅源/Home 点击进入详情页，按钮在 detailCard 右上角；
   备份详情页按钮在页面内容顶部。窗口左上红绿灯旁不再出现操作按钮。
