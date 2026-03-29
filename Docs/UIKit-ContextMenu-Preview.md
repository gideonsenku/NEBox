# UIKit Context Menu Preview — Snapshot 方案

## 问题

在 `UICollectionView` 中使用 `UIContextMenuConfiguration` 时，如果直接将 cell 内的 live view（如 `cardView`）传给 `UITargetedPreview`，UIKit 会在 context menu dismiss 动画过程中**临时修改该 view 的图层属性**（`backgroundColor`、`cornerRadius`、`alpha` 等），导致卡片出现约 2 秒的透明/圆角丢失现象。

## 解决方案

使用 `snapshotView` 代替 live view 作为 preview 目标，配合 `resetAppearance()` 做多层防护。

### 1. 使用 Snapshot 构建 Preview

```swift
private func cardPreview(cv: UICollectionView, config: UIContextMenuConfiguration) -> UITargetedPreview? {
    guard let ip = config.identifier as? IndexPath,
          let cell = cv.cellForItem(at: ip) as? SubCardCell else { return nil }

    // 用 snapshot 而非 live view，防止 UIKit 修改原始 view 的图层属性
    guard let snapshot = cell.cardView.snapshotView(afterScreenUpdates: false) else { return nil }
    snapshot.frame = cell.cardView.bounds
    snapshot.layer.cornerRadius = cell.cardView.layer.cornerRadius
    snapshot.layer.cornerCurve = cell.cardView.layer.cornerCurve
    snapshot.layer.masksToBounds = true

    let params = UIPreviewParameters()
    params.backgroundColor = .clear
    params.visiblePath = UIBezierPath(
        roundedRect: cell.cardView.bounds,
        cornerRadius: cell.cardView.layer.cornerRadius
    )
    // 锚定到 contentView，让 UIKit 知道 snapshot 的归属容器
    let target = UIPreviewTarget(
        container: cell.contentView,
        center: CGPoint(x: cell.cardView.frame.midX, y: cell.cardView.frame.midY)
    )
    return UITargetedPreview(view: snapshot, parameters: params, target: target)
}
```

### 2. Cell 提供 `resetAppearance()` 方法

将所有视觉属性集中在一个方法中，便于多处调用：

```swift
final class SubCardCell: UICollectionViewCell {
    // 提取为 static，保证 reset 时颜色一致
    private static let cardBorderColor = UIColor(
        red: 229/255, green: 228/255, blue: 225/255, alpha: 1
    ).cgColor

    func resetAppearance() {
        cardView.backgroundColor = .white
        cardView.alpha = 1
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Self.cardBorderColor
    }
}
```

### 3. 三处调用 `resetAppearance()`

| 调用位置 | 作用 |
|---------|------|
| `willEndContextMenuInteraction` — 立即 + `animator?.addCompletion` | dismiss 开始和完成时双重恢复 |
| `prepareForReuse()` | cell 复用时恢复 |
| `cellForItemAt` 配置前 | 兜底，确保每次展示都正确 |

```swift
// Coordinator
func collectionView(_ cv: UICollectionView,
                    willEndContextMenuInteraction configuration: UIContextMenuConfiguration,
                    animator: UIContextMenuInteractionAnimating?) {
    guard let ip = configuration.identifier as? IndexPath,
          let cell = cv.cellForItem(at: ip) as? SubCardCell else { return }
    cell.resetAppearance()               // 立即恢复
    animator?.addCompletion {
        cell.resetAppearance()           // 动画结束后再次恢复
    }
}

// Cell
override func prepareForReuse() {
    super.prepareForReuse()
    resetAppearance()
}
```

## 适用范围

项目中所有使用 `UICollectionView` + Context Menu + 自定义卡片样式的场景都应遵循此方案：

- `SubCollectionViewWrapper`（订阅列表）— 已应用
- `CollectionViewWrapper`（首页收藏）— 如遇同类问题，按此方案处理

## 核心原则

> **永远不要把需要保持外观的 live view 直接传给 `UITargetedPreview`。用 snapshot。**
