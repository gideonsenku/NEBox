# Profile 导航栏滚动头像效果 - 需求文档

## 功能概述

优化 Profile 页导航栏：移除左侧 icon + "我的" 文本，改为滚动时显示用户头像和名称，实现 ProfileHeaderCard 中头像/名称"飘移"到导航栏的视觉过渡效果。

---

## 需求列表

### REQ-1: 移除导航栏左侧静态内容

**用户故事**: 作为用户，我希望导航栏左侧不再显示固定的 icon 和"我的"文字，使界面更简洁。

**验收标准 (EARS 格式)**:

1. **REQ-1.1** [Ubiquitous]: ProfileNavBar **应当**移除左侧的方形 icon 和"我的"文本。
2. **REQ-1.2** [Ubiquitous]: 右侧的齿轮设置按钮**应当**保留不变。

### REQ-2: 滚动时导航栏显示头像和名称

**用户故事**: 作为用户，当我向上滚动页面后 ProfileHeaderCard 离开可视区域时，我希望在导航栏看到我的头像和名称。

**验收标准 (EARS 格式)**:

1. **REQ-2.1** [State-driven]: 当 ProfileHeaderCard 未滚出屏幕时，导航栏左侧**应当**为空（不显示头像和名称）。
2. **REQ-2.2** [Event-driven]: 当 ProfileHeaderCard 滚出可视区域后，导航栏左侧**应当**显示用户头像（缩小版）和名称。
3. **REQ-2.3** [Ubiquitous]: 导航栏中的头像**应当**与 ProfileHeaderCard 中的头像保持一致（相同 URL 或默认头像）。
4. **REQ-2.4** [Ubiquitous]: 导航栏中的名称**应当**与 ProfileHeaderCard 中的名称保持一致。

### REQ-3: 平滑过渡动画

**用户故事**: 作为用户，我希望头像和名称出现在导航栏时有平滑的过渡效果，像是从卡片中"移动"上去的。

**验收标准 (EARS 格式)**:

1. **REQ-3.1** [Ubiquitous]: 头像和名称在导航栏的出现/消失**应当**使用 opacity + scale 过渡动画。
2. **REQ-3.2** [Ubiquitous]: 动画**应当**跟随滚动进度平滑变化，而非突然切换。

---

## 边缘情况

1. **EC-1**: 用户无头像和名称 — 使用默认头像（蓝色圆形 person.fill）和默认名称"大侠, 请留名!"
2. **EC-2**: 快速滚动 — 动画应基于滚动偏移量计算，自然跟随

---

## 技术约束

1. **TC-1**: 使用 SwiftUI `GeometryReader` 或 `PreferenceKey` 跟踪 ProfileHeaderCard 的滚动位置
2. **TC-2**: 导航栏头像尺寸约 28-32pt（原 ProfileHeaderCard 为 64pt）
3. **TC-3**: 所有改动限于 ProfileView.swift 文件内

---

## 成功标准

1. **SC-1**: 导航栏左侧无静态 icon 和"我的"文字
2. **SC-2**: 滚动到 ProfileHeaderCard 不可见时，导航栏平滑显示头像+名称
3. **SC-3**: 滚动回顶部时，导航栏头像+名称平滑消失
