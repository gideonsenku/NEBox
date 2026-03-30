# SwiftUI 滚动驱动动画最佳实践

## 背景

在 Relay 项目 Profile 页实现"滚动时头像从 HeaderCard 漂移到导航栏"的效果时，经历了多轮迭代才找到可靠方案。本文档记录踩坑过程和最终方案，供后续类似需求参考。

---

## 最终方案：GeometryReader + onChange + .global 双测量

### 核心思路

在导航栏和目标视图上各放一个 `GeometryReader`，都读 `.global` 坐标系，用两者的位置差值计算 `progress(0~1)`，驱动动画属性。

### 代码模式

```swift
struct SomeView: View {
    @State private var navBarBottomY: CGFloat = 0
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack {
                    // 被追踪的视图
                    TargetCard()
                        .background(
                            GeometryReader { geo in
                                let minY = geo.frame(in: .global).minY
                                Color.clear
                                    .onChange(of: minY) { newMinY in
                                        guard navBarBottomY > 0 else { return }
                                        let distance = newMinY - navBarBottomY
                                        progress = max(0, min(1, -distance / 56))
                                    }
                            }
                        )
                }
            }

            // 导航栏（覆盖在 ScrollView 上方）
            NavBar(progress: progress)
                .overlay(
                    GeometryReader { geo in
                        let bottomY = geo.frame(in: .global).maxY
                        Color.clear
                            .onAppear { navBarBottomY = bottomY }
                            .onChange(of: bottomY) { navBarBottomY = $0 }
                    }
                )
        }
    }
}
```

### Progress 计算公式

```
distance = targetView.global.minY - navBar.global.maxY

distance > 0  → 目标视图在导航栏下方 → progress = 0
distance = 0  → 目标视图顶部刚到导航栏底部 → 过渡开始
distance = -H → 目标视图已滚过导航栏高度 H → progress = 1

progress = clamp(0, 1, -distance / navBarHeight)
```

### 漂移动画效果

```swift
// 导航栏中的头像+名称
HStack {
    avatar
    name
}
.offset(y: (1 - progress) * 16)       // 从下方 16pt 滑入
.opacity(Double(progress))              // 渐入
.scaleEffect(0.85 + 0.15 * progress,   // 从 85% 放大到 100%
             anchor: .leading)

// HeaderCard 中的头像+名称（可选，增强漂移感）
avatarView
    .scaleEffect(1 - 0.15 * progress)   // 缩小
    .opacity(1 - Double(progress) * 0.6) // 淡出
```

---

## 踩坑记录

### ❌ 方案一：PreferenceKey + .named coordinateSpace

```swift
// 失败原因：PreferenceKey 在 NavigationStack 内传播不可靠
ScrollView { ... }
    .coordinateSpace(name: "scroll")
    .onPreferenceChange(Key.self) { value in ... }
```

**问题**：`onPreferenceChange` 在 `NavigationStack`/`NavigationView` 包裹下经常不触发，导致滚动时值不更新。

### ❌ 方案二：PreferenceKey + .global + onPreferenceChange 在 ZStack 层级

```swift
ZStack {
    ScrollView { content.background(GeometryReader { ... preference ... }) }
    NavBar(...)
}
.onPreferenceChange(Key.self) { ... }
```

**问题**：即使把 `onPreferenceChange` 提到 ZStack 级别，在 `neboxNavigationContainer`（NavigationStack 包装器）内仍然不可靠。

### ❌ 方案三：VStack background 追踪整体偏移

```swift
ScrollView {
    VStack { ... }
        .background(GeometryReader { proxy in
            Color.clear.preference(key: Key.self,
                value: -proxy.frame(in: .named("scroll")).origin.y)
        })
}
.coordinateSpace(name: "scroll")
.onPreferenceChange(Key.self) { scrollOffset in ... }
```

**问题**：同样依赖 PreferenceKey 传播，在 NavigationStack 内不可靠。

### ⚠️ 方案四：GeometryReader + onChange + 硬编码阈值

```swift
.onChange(of: minY) { newMinY in
    let threshold: CGFloat = 80 // 硬编码
    navBarProgress = max(0, min(1, scrolled / threshold))
}
```

**问题**：`onChange` 能正常工作（解决了 PreferenceKey 的问题），但硬编码的阈值在不同机型上表现不一致——iPhone 17 Pro 的安全区域高度与其他机型不同，导致过渡时机偏离。

### ✅ 方案五（最终）：GeometryReader + onChange + .global 双测量

见上方"最终方案"部分。

---

## 关键原则

| 原则 | 说明 |
|------|------|
| **不用 PreferenceKey 穿透 NavigationStack** | 传播不可靠，是最常见的坑 |
| **不硬编码安全区域或设备相关的 pt 值** | 用双测量点的差值，设备差异自动抵消 |
| **不用 `withAnimation` 包裹滚动更新** | 导致动画滞后于手指，直接赋 @State |
| **用 `.global` 坐标系** | `.named` 坐标系在复杂视图层级中容易出问题 |
| **用 `onChange(of:)` 而非 `onPreferenceChange`** | 在 GeometryReader 内直接响应几何变化，不依赖 preference 传播链 |
| **双测量点（参考视图 + 目标视图）** | 两个 GeometryReader 都读 `.global`，差值自动适配任何设备 |
