# Relay macOS 功能对齐 - Codex 接手说明

> 从 Claude Opus 4.7 会话交接给 Codex。当前状态：6 批次已实现，Codex 审查的 2 个阻断已修复，双构建通过，但用户在运行后回复「需要调整」——未具体说明，需要你先跑起来看问题再定。

## 当前状态快照（2026-04-18）

- ✅ Xcode 项目：同一 `Relay.xcodeproj` 内有 `Relay` (iOS 15+) 和 `RelayMac` (macOS 26+) 两个 target
- ✅ 双构建：`xcodebuild -scheme Relay` + `xcodebuild -scheme RelayMac -destination 'platform=macOS'` 均 BUILD SUCCEEDED
- ✅ Xcode target 为 **PBXFileSystemSynchronizedRootGroup**：`RelayMac/` 目录下新增 Swift 文件**自动**加入 target，无需改 pbxproj
- ✅ 共享代码位置：`Relay/Models/` `Relay/ViewModels/` `Relay/Services/` `Relay/Managers/` `Relay/Helpers/PlatformBridge.swift / PlatformColors.swift / PlatformImage.swift`（通过显式 Target Membership 被双 target 使用）
- ⚠️ `Relay/Helpers/Vibration.swift` 和 `Relay/Extension/ViewModifier.swift` 仍为 iOS-only（别加入 RelayMac target）

## 交接前完成的事

### 之前的 Nexus 会话（不在本次范围）
- 批次 1-7：macOS target 配置、共享层跨平台抽象、NavigationSplitView/Sidebar 骨架、Onboarding、Home、Subscribe、AppDetail（基础 Form）、Preferences（基础）、Logs、Backup（基础）、Script Editor、About、菜单命令、URL 处理
- 关键根因修复：`GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_FILE = RelayMac/Info.plist`（避免沙箱 `_libsecinit_appsandbox` 崩溃）
- 导航重构：移除 Sheet，改 NavigationStack + MacRoute 推送

### 本次 Nexus（这次交接的范围）
需求/设计/任务：`.claude/specs/macos-feature-parity/requirements.md / design.md / tasks.md`

用户挑选做 **1+3+4+5+6**（排除 2 收藏订阅 CRUD + 7 静态页）：

| # | 功能 | 主要文件 |
|---|------|----------|
| 1 (P0) | App 详情 Session + 脚本运行 | `RelayMac/Views/AppDetail/SessionRow.swift` `SessionListSection.swift` `RenameSessionPopover.swift` `ScriptsSection.swift`，更新 `MacAppDetailView.swift` |
| 3 (P1) | 全局搜索 | `RelayMac/Views/Search/MacSearchView.swift` `SearchResultRow.swift` |
| 4 (P1) | 备份详情 + Revert | `RelayMac/Views/Backup/MacBackupDetailView.swift`，更新 `MacBackupView.swift` |
| 5 (P2) | Profile 页 | `RelayMac/Views/Profile/MacProfileView.swift` `EditAvatarPopover.swift` `StatsCard.swift` |
| 6 (P3) | Preferences 完整偏好 | 更新 `RelayMac/Views/Preferences/MacPreferencesView.swift` 新增 8 Toggle |

基础层扩展：
- `SidebarItem` 新增 `.search` / `.profile`
- `MacRoute` 新增 `.backup(id:)`
- `DetailRouter` / `MacRouteDestination` 对应分支
- 共享 ViewModel 新增 `cloneAppSession(_:)` 方法（`Relay/ViewModels/BoxJsViewModel.swift` ~315 行，iOS 当前未调用但已存在）

### Codex 审查后的修复
1. **阻断**：`updateData` 只暂存到 `pendingDataUpdates`，不自动落库 → 在 `MacPreferencesView.prefBinding` 和 `MacSearchView.toggleFavorite` 里每次 updateData 后追加 `Task { await boxModel.flushPendingDataUpdates() }`
2. **阻断**：`MacBackupDetailView.revert` 无条件 dismiss → 改为只有备份确实消失时才 pop back
3. **建议**：`MacAppDetailView.save` 立即置 saving=false 导致 loading 不可见 → 加 400ms sleep 再置回
4. **小优化**：`SessionRow.dataSummary` 嵌套字典长字符串化 — 未处理，低优先级

### 未做（留给你）
- **#2**：收藏/订阅增删重排（FORCE 跳过）
- **#7**：版本历史 / 致谢 / 免责 / BoxJS 安装引导（FORCE 跳过）
- `SessionListSection.createEmpty()` 里用 `app.keys` 过滤 → 若 `keys` 为空则用整个 `datas`，这可能把无关数据也存进去，用户实机可能会抱怨
- Session 导入 JSON（iOS 有，当前 macOS 延后）
- Data Viewer（iOS 有，当前 macOS 缺）
- HTML 描述渲染（iOS 有，当前 macOS 缺）

## 用户的最后一条反馈：「需要调整」

用户在验收环节选择了「需要调整」但**没有说明具体问题**。你接手后**第一件事**应该是：

1. 让用户描述他们在运行时看到的具体问题（哪个视图、什么操作、期望/实际结果）
2. 如果是崩溃 → 索取堆栈
3. 如果是功能不生效 → 先查 `flushPendingDataUpdates` 是否真的被调用（可以让用户看 macOS Console 或 `~/Library/Containers/net.sodion.RelayMac/Data/Library/Caches/Relay/logs/relay.log`）

## 构建命令备忘

```bash
# 切到项目根
cd /Users/senku/develop/repo/NEBox

# macOS
xcodebuild -project Relay.xcodeproj -scheme RelayMac \
  -destination 'platform=macOS' -configuration Debug build

# iOS 回归（每次重大改动都跑）
xcodebuild -project Relay.xcodeproj -scheme Relay \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

## Xcode 项目约定（别踩坑）

- **别动** `Relay.xcodeproj/project.pbxproj` 的 Sources build phase 里 `E24439B*` / `E24439D*` / `E24439E*` / `E24439F*` 这些 UUID — 是手动加的共享文件引用
- **别改** `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_FILE = RelayMac/Info.plist` 的配置（这是关键的"合并模式"，改错了沙箱崩溃）
- **别改** `SWIFT_DEFAULT_ACTOR_ISOLATION`（已关闭；iOS target 没有这个设置）
- **别把** `Relay/Views/` 下的 iOS 视图加入 RelayMac target（架构原则：iOS 视图不复用）
- **别把** `Relay/Helpers/Vibration.swift` 加入 RelayMac target（iOS 专有；macOS 通过 `PlatformBridge.impact` 处理）

## 共享 ViewModel 关键 API

```swift
// Data
updateData(path:, data:)           // 乐观本地 + 暂存 pendingDataUpdates；需 flush
updateDataAsync(path:, data:)      // 同步等待服务器
flushPendingDataUpdates() async    // 推送所有 pending 改动
saveData(params:)                  // saveDatas 的 fire-and-forget
fetchData() / fetchDataAsync()     // 全量刷新
// Session
saveAppSession(app:, datas:)
delAppSession(sessionId:)
updateAppSession(_:)               // 用来重命名：改完 session.name 后整体传入
useAppSession(sessionId:, appId:)  // 应用到 datas
linkAppSession(sessionId:, appId:) // 绑定 curSessions
cloneAppSession(_:)                // 本次新增
// Backup
saveGlobalBak(name:)
impGlobalBak(bakData:, name:)
delGlobalBak(id:)
revertGlobalBak(id:)
updateGlobalBak(id:, name:)
// Subscription
addAppSub(url:)
```

## 数据模型要点

```swift
struct BoxDataResp {
    let appSubCaches: [String: AppSubCache]   // url → cache
    let datas: [String: AnyCodable?]          // ⚠️ 双层可选：subscript 返回 AnyCodable??
    let sessions: [Session]                   // 全局，需按 appId 过滤
    let usercfgs: UserConfig?
    let globalbaks: [GlobalBackup]?
    let curSessions: [String: String]?        // appId → sessionId
    let syscfgs: SysConfig?                   // 含 env: "Loon"|"Surge"|...
}

struct UserConfig {                           // 所有 Toggle 字段都是 Bool?
    let favapps: [String]                     // 应用 id 数组
    let isMute: Bool?
    let isMuteQueryAlert: Bool?
    let isHideHelp: Bool?
    let isHideBoxIcon: Bool?
    let isHideMyTitle: Bool?
    let isHideCoding: Bool?
    let isHideRefresh: Bool?
    let isDebugWeb: Bool?
    let icon: String?                         // 头像 URL
    let name: String?                         // 昵称
    // ... 其它见 Relay/Models/BoxDataModel.swift:271
}
```

## 推荐的起步动作

1. 读 `.claude/specs/macos-feature-parity/requirements.md` + `design.md`（20 分钟）
2. 让用户具体说「需要调整」是什么问题
3. 若是小问题 → 直接修 + 双构建验证
4. 若用户想继续推进，排在优先队列的是：
   - **P0 的第 2 项（本次跳过了）**：收藏/订阅增删重排（HStack + Button 即可做简单版，可选）
   - **静态页**：版本历史、致谢、免责、BoxJS 引导（复用 iOS 的 Markdown 内容）
   - **Data Viewer**：iOS 的 `DataViewerView.swift` 很完整，可以照搬一份 Mac 版
   - **App scripts 运行失败的 URL resolving**：如果 `script.script` 是相对路径，需要拼接 `ApiManager.shared.baseURL`

## 用户风格（沟通提示）

- 中文交流
- 喜欢快速迭代，讨厌冗长的 Spec（本次是个例外，他要求正规 Nexus）
- 会精准反馈具体 bug（如堆栈、symbol name）
- 对 macOS 原生设计语言有品味，反感 iPhone 移植感（这点已经在 design.md 体现）
