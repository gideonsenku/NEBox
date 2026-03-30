# Profile 导航栏滚动头像效果 - 实施任务清单

## 概述

基于需求和设计文档的原子化任务列表，按执行批次分组。所有改动在 ProfileView.swift 内完成。

---

## 批次 1: 基础设施（串行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 1.1 | 新增 ScrollOffsetPreferenceKey 结构体 | Claude | ≤2min | - | ProfileView.swift |
| 1.2 | 为 ProfileHeaderCard 添加 GeometryReader background 上报 minY | Claude | ≤3min | 1.1 | ProfileView.swift |
| 1.3 | 在 ScrollView 上添加 coordinateSpace 命名，ProfileView 添加 @State navBarProgress | Claude | ≤2min | 1.2 | ProfileView.swift |

**批次完成标准**: PreferenceKey 定义完成，HeaderCard 能上报位置，ProfileView 持有 progress 状态

---

## 批次 2: NavBar 改造（串行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 2.1 | 改造 ProfileNavBar：移除左侧 icon+"我的"，新增 usercfgs 和 progress 参数 | Claude | ≤3min | 1.3 | ProfileView.swift |
| 2.2 | 在 ProfileNavBar 中实现缩小头像视图（复用 avatarView 逻辑，32pt）| Claude | ≤3min | 2.1 | ProfileView.swift |
| 2.3 | 添加 opacity + scaleEffect 动画绑定 progress | Claude | ≤2min | 2.2 | ProfileView.swift |

**批次完成标准**: NavBar 显示头像+名称，受 progress 控制

---

## 批次 3: 集成与调优（串行）

| ID | 任务 | 执行器 | 预估 | 依赖 | 输出文件 |
|----|------|--------|------|------|----------|
| 3.1 | 在 ProfileView.body 中接入 onPreferenceChange 计算 progress 并传递给 NavBar | Claude | ≤3min | 2.3 | ProfileView.swift |
| 3.2 | 调优 threshold 值和动画曲线，确保过渡自然 | Claude | ≤2min | 3.1 | ProfileView.swift |

**批次完成标准**: 编译通过，滚动时导航栏头像平滑显示/隐藏

---

## 执行策略

### 批次执行顺序

```
批次 1 (串行) → 批次 2 (串行) → 批次 3 (串行)
```

### 预估时间

| 批次 | 任务数 | 并行度 | 预估时间 |
|------|--------|--------|----------|
| 批次 1 | 3 | 串行 | 7min |
| 批次 2 | 3 | 串行 | 8min |
| 批次 3 | 2 | 串行 | 5min |
| **总计** | **8** | - | **20min** |
