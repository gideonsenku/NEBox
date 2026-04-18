# RelayMac 详情页 Toolbar 修复 - 实施任务清单

## 概述

按批次原子化执行。所有任务由 Claude 本地直接 Edit（CLAUDE_ONLY 模式）。

---

## 批次 1: MacAppDetailView 迁移（串行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 1.1 | MacAppDetailView: 移除 `.toolbar {}` 块和 `.navigationTitle/.navigationSubtitle`；新增 inline `headerSection` 作为 WorkbenchPageScroll 首节渲染 app.name + app.author.asHandle | Claude | ≤5min | - | RelayMac/Views/AppDetail/MacAppDetailView.swift |
| 1.2 | MacAppDetailView: 新增 `updateChrome()` 私有方法，把原 toolbar 里的 Save 按钮 + 更多菜单转为 `chrome.setActions(...)`；在 `.onAppear` 和 `.onChange/onReceive` 触发 updateChrome | Claude | ≤5min | 1.1 | RelayMac/Views/AppDetail/MacAppDetailView.swift |
| 1.3 | MacAppDetailView: 在 body 最外层附加一个隐藏的 Button 保留 ⌘S 快捷键 | Claude | ≤3min | 1.2 | RelayMac/Views/AppDetail/MacAppDetailView.swift |

**批次完成标准**: 文件编译通过；grep 已无 `.toolbar`/`.navigationTitle`/`.navigationSubtitle`。

---

## 批次 2: MacSubscribeDetailView + MacBackupDetailView（可并行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 2.1 | MacSubscribeDetailView: 移除 `.navigationTitle/.navigationSubtitle`；扩展 header 渲染 sub.name 和 sub.author.asHandle（大号标题 + 副标题） | Claude | ≤3min | 批次1 | RelayMac/Views/Subscribe/MacSubscribeDetailView.swift |
| 2.2 | MacBackupDetailView: 移除 `.toolbar { toolbar(for: bak) }` 和 `.navigationTitle`；新增 inlineHeader(for:) 作为 content(for:) 首节，HStack 左标题+时间，右 3 个 icon 按钮（恢复/复制 JSON/导出）；删除 `toolbar(for:)` 辅助函数 | Claude | ≤5min | 批次1 | RelayMac/Views/Backup/MacBackupDetailView.swift |

**批次完成标准**: 两文件编译通过；grep 无 `.toolbar`/`.navigationTitle`/`.navigationSubtitle`。

---

## 批次 3: 验证（串行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 3.1 | `xcodebuild RelayMac scheme` 编译通过 | Claude | ≤5min | 2.x | （终端输出） |
| 3.2 | `grep -rn '\.toolbar\|navigationTitle\|navigationSubtitle' RelayMac/Views/AppDetail RelayMac/Views/Subscribe RelayMac/Views/Backup` 无残留 | Claude | ≤2min | 3.1 | （终端输出） |

**批次完成标准**: 编译绿 + grep 残留为 0。

---

## 执行策略

### 批次执行顺序

```
批次 1 (串行 1.1→1.2→1.3) → 批次 2 (并行 2.1/2.2) → 批次 3 (串行)
```

### 预估时间

| 批次 | 任务数 | 并行度 | 预估时间 |
|------|--------|--------|----------|
| 批次 1 | 3 | 串行 | ~13min |
| 批次 2 | 2 | 并行 | ~5min |
| 批次 3 | 2 | 串行 | ~7min |
| **总计** | **7** | - | **~25min** |
