# Relay macOS 功能对齐 - 需求文档

## 功能概述

补齐 RelayMac 相对 iOS Relay 缺失的 5 组功能，按 macOS 原生设计语言（Liquid Glass + 桌面交互习惯）实现。

**本次范围**（用户选定 1/3/4/5/6）：
1. **P0**：应用详情页 Session 管理 + 应用脚本运行
2. **P1**：全局搜索
3. **P1**：备份详情 + Revert + 内容查看 + 改名 + 复制/导出
4. **P2**：Profile 页（头像 / 昵称 / 统计）
5. **P3**：PreferencesView 完整偏好

**范围之外**：收藏/订阅 CRUD（排序/增删）、静态页（版本历史/致谢/免责/BoxJS 引导）。

**设计语言约束**：
- 所有编辑用 **Popover / Sheet / Inspector**，不做 iPhone 式底部弹层
- 列表支持 **swipeActions + contextMenu**，不实现 iOS 拖拽编辑模式
- 表单用 `Form` + `LabeledContent`，不用 iPhone 圆角白底卡片
- 图标 / 材质统一 macOS 26 Liquid Glass（`.glassEffect`、`.regularMaterial`）
- 菜单动作优先用 **Menu / ToolbarItem**，不做 iOS 底部 FAB

---

## 需求列表

### REQ-1: 应用详情 Session 管理

**用户故事**：作为 BoxJS 用户，我想要在 macOS 上管理应用的多个会话（创建/切换/克隆/删除/重命名），这是 BoxJS 的核心卖点。

**验收标准**：
1. **REQ-1.1** [Ubiquitous]：`MacAppDetailView` **应当**在「设置」Section 下增加「会话」Section，列出该应用所有 Session。
2. **REQ-1.2** [Ubiquitous]：Session 行**应当**显示：序号、会话名、创建时间、是否当前激活（check 标识）、关键 key-val 摘要（最多 3 条）。
3. **REQ-1.3** [State-driven]：当用户右键（contextMenu）单个 Session 时，系统**应当**提供：使用（激活）、克隆、重命名、复制 JSON、删除。
4. **REQ-1.4** [State-driven]：当用户悬停 Session 行时，行末**应当**出现 trailing swipe actions：使用 / 克隆 / 删除（macOS 26 `.swipeActions`）。
5. **REQ-1.5** [Event-driven]：点击「使用」**应当**调用 `boxModel.useAppSession()`，并在列表实时反映激活状态变化。
6. **REQ-1.6** [Event-driven]：点击「重命名」**应当**弹出 Popover 输入新名，回车或点击「完成」调用 `boxModel.updateAppSession(name:)`。
7. **REQ-1.7** [Event-driven]：点击「克隆」**应当**调用 `boxModel.cloneAppSession()`，在列表末尾追加副本。
8. **REQ-1.8** [Ubiquitous]：Session 区块**应当**提供「新建 Session」按钮（Section header trailing），调用新建空 Session 的 ViewModel 方法。
9. **REQ-1.9** [Unwanted]：Session 删除**不应当**直接执行；**应当**先弹出 NSAlert 确认。

### REQ-2: 应用脚本运行

**用户故事**：作为用户，我想要在应用详情里直接运行 `app.scripts` 列表中的脚本（BoxJS 内建任务）。

**验收标准**：
1. **REQ-2.1** [Ubiquitous]：当 `app.scripts` 非空时，`MacAppDetailView` **应当**显示「脚本」Section。
2. **REQ-2.2** [Ubiquitous]：每个脚本行**应当**显示：序号、脚本名、运行按钮（Label "运行" + "play.circle" icon）。
3. **REQ-2.3** [Event-driven]：点击「运行」**应当**调用 `NetworkProvider.request(.runScript(url:))`，按钮进入 loading 状态。
4. **REQ-2.4** [Event-driven]：运行完成后，**应当**通过 Toast 提示成功/失败。
5. **REQ-2.5** [State-driven]：同一脚本在运行中时，按钮**应当**禁用，避免并发触发。

### REQ-3: 全局搜索

**用户故事**：作为用户，我想要在所有可用应用中搜索指定 ID / 名称，并快速收藏/取消收藏。

**验收标准**：
1. **REQ-3.1** [Ubiquitous]：侧边栏「应用」分组**应当**新增「搜索」条目（`SidebarItem.search`，SF Symbol `magnifyingglass`）。
2. **REQ-3.2** [Ubiquitous]：`MacSearchView` **应当**使用 macOS 原生 `.searchable(text:)` 搜索栏，显示在工具栏。
3. **REQ-3.3** [Ubiquitous]：搜索结果**应当**使用 `List` 展示，每行：应用图标、应用名 + ID、作者、收藏按钮（star/star.fill，蓝色）。
4. **REQ-3.4** [Event-driven]：点击行**应当**推送到 `MacAppDetailView`（复用已有导航路由）。
5. **REQ-3.5** [Event-driven]：点击收藏按钮**应当**调用 `boxModel.updateData(path: "usercfgs.favapps", data:)`，切换收藏状态。
6. **REQ-3.6** [State-driven]：搜索为空时**应当**显示空态引导（"输入关键词搜索应用"）。
7. **REQ-3.7** [Optional]：如果搜索框聚焦，⌘F **可以**从任意页面切换到搜索页。

### REQ-4: 备份详情 + Revert

**用户故事**：作为用户，我想要查看备份内容、恢复某个备份、编辑备份名、复制备份 JSON、导出备份文件。

**验收标准**：
1. **REQ-4.1** [Ubiquitous]：`MacBackupView` 的备份行**应当**支持点击导航到 `MacBackupDetailView`（推入导航栈）。
2. **REQ-4.2** [Ubiquitous]：`MacBackupDetailView` **应当**显示：Hero 区（icloud 图标 + 名称 + 时间）、TextField 编辑名称、JSON 内容预览（代码块）。
3. **REQ-4.3** [Ubiquitous]：工具栏**应当**提供：恢复（Revert，带确认 NSAlert）、复制 JSON、导出文件（NSSavePanel）。
4. **REQ-4.4** [Event-driven]：点击「恢复」**应当**调用 `boxModel.revertGlobalBak(id:)`，成功后 Toast + Pop back。
5. **REQ-4.5** [Event-driven]：修改名称后按 Enter **应当**调用 `boxModel.updateGlobalBak(id:, name:)`，Toast 提示。
6. **REQ-4.6** [Ubiquitous]：JSON 预览**应当**使用等宽字体、滚动视图、可选中复制。
7. **REQ-4.7** [State-driven]：Revert 确认 NSAlert 文案**应当**明确警告"此操作将覆盖当前数据，不可撤销"。

### REQ-5: Profile 页（头像 / 昵称 / 统计）

**用户故事**：作为用户，我想要在 macOS 上查看并编辑我的 Profile（头像、昵称、统计），匹配 iOS 版体验。

**验收标准**：
1. **REQ-5.1** [Ubiquitous]：侧边栏「系统」分组**应当**新增「个人资料」条目（`SidebarItem.profile`，SF Symbol `person.crop.circle`），置于「偏好设置」之前。
2. **REQ-5.2** [Ubiquitous]：`MacProfileView` **应当**分为三个 Section：头像卡片、昵称 + API 地址、统计卡片。
3. **REQ-5.3** [Ubiquitous]：头像显示优先级**应当**为 `AvatarStorage.load()` → `usercfgs.icon` URL → 默认占位（SF Symbol）。
4. **REQ-5.4** [Event-driven]：点击「编辑头像」**应当**弹出 Popover/Sheet 提供 2 种选项：从本地选择图片（NSOpenPanel 选 `public.image`）或粘贴图片 URL。
5. **REQ-5.5** [Event-driven]：选本地图片**应当**调用 `AvatarStorage.save(_:)`，图片复制到沙箱，立即刷新头像。
6. **REQ-5.6** [Event-driven]：粘贴 URL **应当**调用 `boxModel.updateDataAsync(path: "usercfgs.icon", data:)` 保存。
7. **REQ-5.7** [Ubiquitous]：昵称字段**应当**用 `LabeledContent` + 内联 TextField，失焦 / Enter 保存。
8. **REQ-5.8** [Ubiquitous]：统计卡片**应当**横向展示：应用数 / 订阅数 / 会话数，使用 `.glassEffect` 玻璃卡片样式。
9. **REQ-5.9** [Optional]：如果头像被本地覆盖，**可以**提供「清除本地头像」按钮还原为 URL 头像。

### REQ-6: PreferencesView 完整偏好

**用户故事**：作为用户，我想要修改 BoxJS 的所有可配置偏好（非 iOS 专有部分）。

**验收标准**：
1. **REQ-6.1** [Ubiquitous]：`MacPreferencesView` **应当**保留现有「BoxJS 服务器」「操作」「关于」三个 Section，新增「BoxJS 偏好」Section。
2. **REQ-6.2** [Ubiquitous]：「BoxJS 偏好」Section **应当**包含以下开关，绑定到 `usercfgs` 对应字段：
   - 勿扰模式 (`isMute`)
   - 勿扰查询警告 (`isMuteQueryAlert`)
   - 隐藏帮助 (`isHideHelp`)
   - 隐藏 Box 图标 (`isHideBoxIcon`)
   - 隐藏我的标题 (`isHideMyTitle`)
   - 隐藏编码 (`isHideCoding`)
   - 隐藏刷新 (`isHideRefresh`)
   - Debug Web (`isDebugWeb`)
3. **REQ-6.3** [State-driven]：当用户切换任意 Toggle 时，系统**应当**乐观更新本地 usercfgs 并调用 `boxModel.updateData(path:, data:)` 异步同步。
4. **REQ-6.4** [Unwanted]：**不应当**实现 iOS 专有项：应用图标切换、图标风格（light/dark/auto）。
5. **REQ-6.5** [Optional]：如果 `usercfgs.httpapi` 非空且 `syscfgs.env` 为 Surge，**可以**显示 HTTP-API 只读字段。
6. **REQ-6.6** [Ubiquitous]：服务器首次未配置时，偏好 Section **应当**禁用 Toggle，显示"请先配置 BoxJS 服务器"提示。
7. **REQ-6.7** [Ubiquitous]：Preferences 应独立可作为 `Settings` Scene（已有）或 Sidebar 项（新增 `SidebarItem.preferences` 已存在）访问。

---

## 边缘情况

1. **EC-1**：Session 列表为空 → 显示 `ContentUnavailableView`（"暂无会话，点击右上角新建"）
2. **EC-2**：脚本 URL 无效 / 网络失败 → Toast 错误提示，按钮恢复可点
3. **EC-3**：搜索结果为空 → 显示 `ContentUnavailableView(.search)` 内建变体
4. **EC-4**：本地头像文件损坏 → 静默 fallback 到 URL 或默认图标
5. **EC-5**：usercfgs 字段缺失（旧服务器）→ Toggle 使用默认值，保存时完整字段写回
6. **EC-6**：Revert 网络失败 → Toast 错误，不 pop back，保留用户当前视图
7. **EC-7**：沙箱无法写入 AvatarStorage 文件 → Toast 错误，继续使用 URL 头像

---

## 技术约束

1. **TC-1**：所有新增视图位于 `RelayMac/Views/` 下对应功能子目录
2. **TC-2**：不修改 `Relay/` 下 iOS 代码（共享 ViewModel 除外）
3. **TC-3**：共享 ViewModel 新增的公开方法必须对 iOS + macOS 都可用
4. **TC-4**：所有 Popover/Sheet 尺寸使用 `.frame(minWidth:minHeight:)` 声明，避免窗口尺寸计算失败
5. **TC-5**：macOS 26 Liquid Glass API（`.glassEffect` / `.buttonStyle(.glass)`）优先使用，`.regularMaterial` 作为回退
6. **TC-6**：新增 UI 字符串统一中文，与现有 macOS 视图保持一致（不引入 Localization）

---

## 成功标准

1. **SC-1**：RelayMac + Relay iOS 两个 scheme 均构建成功，零 warning 新增
2. **SC-2**：应用详情里可以看到并操作 Session（使用/克隆/删除/重命名）
3. **SC-3**：应用详情里 Scripts 区可运行至少 1 个脚本看到 Toast 结果
4. **SC-4**：侧边栏 "搜索" 可过滤 `boxData.apps` 并点击星标切换收藏
5. **SC-5**：备份列表里点击某个备份进入详情，可 Revert / 复制 / 导出 / 改名
6. **SC-6**：Profile 页可编辑昵称 + 切换头像（本地或 URL），统计数字实时刷新
7. **SC-7**：Preferences 新增 8 个 Toggle 均可乐观更新并同步到服务器
