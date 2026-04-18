# RelayMac Dark Mode 适配 - 实施任务清单

## 概述

基于 requirements.md 和 design.md 的原子化任务清单，按执行批次分组。所有任务由 Claude 执行（CLAUDE_ONLY 模式）。

---

## 批次 1: 共享基础设施（串行依赖）

此批次先建立共享 modifier 和修复强制 light，后续批次可引用。

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 1.1 | 在 `WorkbenchSurfaces.swift` 新增 `workbenchPanelBackground` 和 `workbenchSubtleFill` 两个 View extension；改造 `WorkbenchWindowBackground` 移除硬编码渐变，改用透明或 `Color(nsColor: .windowBackgroundColor)` | Claude | ≤5min | - | RelayMac/Views/Components/WorkbenchSurfaces.swift |
| 1.2 | 移除 `SidebarView.swift:87` 的 `.environment(\.colorScheme, .light)` 强制 | Claude | ≤2min | - | RelayMac/Views/RootWindow/SidebarView.swift |
| 1.3 | 修复 `MainWindowView.swift:63` 的 `Color.white.opacity(0.92)` → `.regularMaterial`（保留 line 85 shadow 与 line 136 primary 白字） | Claude | ≤3min | 1.1 | RelayMac/Views/RootWindow/MainWindowView.swift |

**批次完成标准**: 3 个文件编辑完成，`xcodebuild` 构建通过。

---

## 批次 2: 各屏幕颜色替换（可并行）

各屏幕互不依赖，可并行修复。应用批次 1 新增的 modifier + canonical 映射表。

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 2.1 | 修复 `MacLogViewerView.swift` 中 ~8 处硬编码颜色（lines 94/98/113/116/134/161/165/252/277/451/459）按映射表替换为 Material / `Color.primary.opacity` / `Color(nsColor:.textBackgroundColor)` | Claude | ≤5min | 1.1 | RelayMac/Views/Logs/MacLogViewerView.swift |
| 2.2 | 修复 `MacScriptEditorView.swift` 中 ~10 处硬编码颜色（lines 100/104/125/129/210/217/221/247/253/257/294/309/316/507/519）按映射表替换（保留 .green 状态指示） | Claude | ≤5min | 1.1 | RelayMac/Views/Script/MacScriptEditorView.swift |
| 2.3 | 修复 `MacDataViewerView.swift` 中 ~9 处硬编码颜色（lines 52/56/89/93/105/114/118/121/290/294/319/353/357）按映射表替换 | Claude | ≤5min | 1.1 | RelayMac/Views/AppDetail/MacDataViewerView.swift |
| 2.4 | 修复 `MacBackupView.swift` 中 ~7 处硬编码颜色（lines 92/96/113/236/240/243/249/253/301/307）按映射表替换；同时检查 `MacBackupDetailView.swift:141` 的 accent tint 保留 | Claude | ≤5min | 1.1 | RelayMac/Views/Backup/MacBackupView.swift<br/>RelayMac/Views/Backup/MacBackupDetailView.swift |
| 2.5 | 修复 `MacPreferencesView.swift` 中 ~6 处硬编码颜色（lines 389/393/396/427/435/438）按映射表替换（保留状态徽章 .green/.red/.orange.opacity(0.1)） | Claude | ≤4min | 1.1 | RelayMac/Views/Preferences/MacPreferencesView.swift |

**批次完成标准**: 5 个文件编辑完成，`xcodebuild` 构建通过，各屏幕 Dark Mode 下无白色孤岛。

---

## 批次 3: 剩余次要屏幕与组件（可并行）

搜索、订阅、应用详情子组件、Onboarding 的残留硬编码修复。

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 3.1 | 审查并修复 `MacAppDetailView.swift` 及其子组件（`SessionRow.swift`、`SettingRowMac.swift` 等）中残留硬编码颜色；确认 `SessionRow.swift:46` 的 `.background(Color.secondary, in: Circle())` 是否已是语义色 | Claude | ≤5min | 1.1 | RelayMac/Views/AppDetail/*.swift |
| 3.2 | 审查并修复 `MacSearchView.swift`、`SearchResultRow.swift` 中残留硬编码颜色 | Claude | ≤4min | 1.1 | RelayMac/Views/Search/*.swift |
| 3.3 | 审查并修复 `MacSubscribeListView.swift`、`MacSubscribeDetailView.swift` 中残留硬编码颜色 | Claude | ≤4min | 1.1 | RelayMac/Views/Subscribe/*.swift |
| 3.4 | 审查并修复 `MacOnboardingSheet.swift` 中残留硬编码颜色（若有 gradient/图片需专项处理） | Claude | ≤4min | 1.1 | RelayMac/Views/Onboarding/*.swift |

**批次完成标准**: 4 个屏幕修复完成，`grep -n 'Color\.white\|Color\.black\|Color(red:'` 在 `RelayMac/` 下剩余项都在 SC-2 "预期保留"清单内。

---

## 批次 4: 验证（串行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 4.1 | 运行 `xcodebuild -project Relay.xcodeproj -scheme RelayMac build` 验证编译无错误无新增 warning | Claude | ≤5min | 2.1-2.5, 3.1-3.4 | （终端输出） |
| 4.2 | 运行 `grep -rn 'Color\.white\|Color\.black\|Color(red:' RelayMac/` 汇总残留项，逐项对照 SC-2 预期保留清单 | Claude | ≤3min | 4.1 | （终端输出 + 报告） |

**批次完成标准**: 构建绿、grep 残留项均为预期保留。

---

## 执行策略

### 批次执行顺序

```
批次 1 (串行: 1.1 → 1.2/1.3) → 批次 2 (并行 5 任务) → 批次 3 (并行 4 任务) → 批次 4 (串行)
```

### 预估时间

| 批次 | 任务数 | 并行度 | 预估时间 |
|------|--------|--------|----------|
| 批次 1 | 3 | 部分串行 | ~10min |
| 批次 2 | 5 | 并行 | ~5min |
| 批次 3 | 4 | 并行 | ~5min |
| 批次 4 | 2 | 串行 | ~8min |
| **总计** | **14** | - | **~28min** |

### 风险缓解

- 每个批次结束后即时更新 TodoWrite。
- 如某文件替换后产生编译错误，回退该文件的改动，在 review 时单独处理。
- Dark/Light 人工走查在阶段 7 验收环节执行（用户操作）。
