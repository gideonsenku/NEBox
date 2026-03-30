# Profile 导航栏滚动头像效果 - 设计文档

## 概述

通过 `PreferenceKey` 跟踪 ProfileHeaderCard 的滚动位置，在 ProfileNavBar 中根据偏移量动态显示/隐藏用户头像和名称，实现平滑过渡效果。

### 设计目标

1. 移除导航栏左侧静态 icon 和"我的"文字
2. 滚动时导航栏左侧平滑显示缩小头像 + 名称
3. 动画跟随滚动进度自然过渡，无突兀跳变

---

## 架构

### 滚动追踪机制

```
ScrollView
  └─ VStack
       └─ ProfileHeaderCard
            └─ GeometryReader (background)
                 └─ 通过 PreferenceKey 上报 minY 值
                      └─ ProfileView.onPreferenceChange
                           └─ 计算 navBarAvatarProgress (0.0 ~ 1.0)
                                └─ 传递给 ProfileNavBar
                                     └─ 控制头像+名称的 opacity & scale
```

### 组件变更

| 组件 | 变更 | 说明 |
|------|------|------|
| `ScrollOffsetPreferenceKey` | **新增** | PreferenceKey，传递 ProfileHeaderCard 的 minY |
| `ProfileNavBar` | **修改** | 移除左侧 icon+"我的"，新增头像+名称（受 progress 控制） |
| `ProfileView.body` | **修改** | 添加 `@State navBarProgress`，读取 PreferenceKey 并计算进度 |
| `ProfileHeaderCard` | **修改** | 添加 GeometryReader background 上报位置 |

---

## 详细设计

### 1. ScrollOffsetPreferenceKey

```swift
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

### 2. ProfileHeaderCard 位置上报

在 ProfileHeaderCard 外层添加 background GeometryReader：

```swift
ProfileHeaderCard(...)
    .background(
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geo.frame(in: .named("profileScroll")).minY
            )
        }
    )
```

### 3. 进度计算

```swift
// headerCard 顶部 minY 值
// 当 minY 从初始位置滚动到导航栏底部时，progress 从 0 → 1
// threshold: headerCard 完全滚出视口的 minY 值（约 navBar 高度 56pt 附近）

let threshold: CGFloat = 80  // headerCard 初始 minY 大约在 56+清除区域
let progress = max(0, min(1, (threshold - scrollOffset) / threshold))
```

- `progress = 0`: headerCard 完全可见，导航栏不显示头像
- `progress = 1`: headerCard 滚出，导航栏完全显示头像

### 4. ProfileNavBar 改造

```swift
struct ProfileNavBar: View {
    let usercfgs: UserConfig?
    let progress: CGFloat  // 0.0 ~ 1.0
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 左侧：滚动后显示头像+名称
            HStack(spacing: 8) {
                // 缩小头像 (32pt)
                avatarView
                    .frame(width: 32, height: 32)

                Text(usercfgs?.name ?? "大侠, 请留名!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
            }
            .opacity(progress)
            .scaleEffect(0.8 + 0.2 * progress, anchor: .leading)

            Spacer()

            // 右侧：设置按钮（保持不变）
            Button(action: onSettings) { ... }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }
}
```

### 5. 动画细节

- **opacity**: 随 progress 线性变化 `0 → 1`
- **scaleEffect**: 从 `0.8 → 1.0`，锚点 `.leading` 使头像从左侧生长
- 无需额外 `withAnimation`，因为 progress 基于滚动偏移量连续变化，自然平滑

---

## 数据流

```
ProfileView (@State navBarProgress: CGFloat = 0)
    │
    ├─ ScrollView(.named("profileScroll"))
    │    └─ ProfileHeaderCard
    │         └─ .background(GeometryReader → PreferenceKey)
    │
    ├─ .onPreferenceChange → 计算 navBarProgress
    │
    └─ ProfileNavBar(usercfgs:, progress: navBarProgress, onSettings:)
```

---

## 错误处理

| 场景 | 处理 |
|------|------|
| 无头像 URL | 显示默认蓝色圆形 person.fill 图标 |
| 无用户名 | 显示"大侠, 请留名!" |
| 快速滚动 | progress 基于几何位置实时计算，无延迟 |
