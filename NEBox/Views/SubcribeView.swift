//
//  SubcribeView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI
import UIKit
import SDWebImage

struct SubcribeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @State private var items: [AppSubCache] = []
    @State private var isEditMode: Bool = false
    @State private var isDragging: Bool = false
    @State private var isScrolled: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(urlString: boxModel.boxData.bgImgUrl)

                if items.isEmpty {
                    emptyState
                } else {
                    SubCollectionViewWrapper(
                        items: $items,
                        boxModel: boxModel,
                        isEditMode: $isEditMode,
                        isDragging: $isDragging,
                        onScroll: { offset in isScrolled = offset < -5 }
                    )
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("应用订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(isScrolled ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !items.isEmpty {
                        Button {
                            isEditMode.toggle()
                        } label: {
                            Text(isEditMode ? "完成" : "编辑")
                                .font(.system(size: 15))
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await boxModel.reloadAppSub(url: "")
                                toastManager.showToast(message: "已刷新全部订阅")
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Button {
                            showTextFieldAlert(title: "添加订阅", message: nil, placeholder: "输入订阅地址", confirmButtonTitle: "确定", cancelButtonTitle: "取消") { inputText in
                                Task {
                                    await boxModel.addAppSub(url: inputText)
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .onReceive(boxModel.$boxData) { data in
            if !isDragging {
                items = data.displayAppSubs
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
            Text("暂无订阅")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct SubCollectionViewWrapper: UIViewRepresentable {
    @Binding var items: [AppSubCache]
    let boxModel: BoxJsViewModel
    @Binding var isEditMode: Bool
    @Binding var isDragging: Bool
    var onScroll: ((CGFloat) -> Void)? = nil

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.register(SubCardCell.self, forCellWithReuseIdentifier: "SubCardCell")
        collectionView.clipsToBounds = false

        context.coordinator.collectionView = collectionView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(context.coordinator.handleRefresh(_:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        // 编辑模式下用于拖拽排序；非编辑模式交给系统 context menu
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.18
        longPressGesture.isEnabled = false
        collectionView.addGestureRecognizer(longPressGesture)
        context.coordinator.reorderLongPressGesture = longPressGesture

        // Tap gesture 用于退出 jiggle 模式，cancelsTouchesInView = false 不干扰正常点击
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tapGesture)

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let previousIds = context.coordinator.lastRenderedIds
        let newIds = items.map { $0.id }
        let editModeChanged = context.coordinator.previousEditMode != isEditMode

        context.coordinator.items = items
        context.coordinator.isEditMode = isEditMode
        context.coordinator.isDragging = isDragging
        context.coordinator.previousEditMode = isEditMode
        context.coordinator.reorderLongPressGesture?.isEnabled = isEditMode

        if !isDragging, previousIds != newIds {
            context.coordinator.lastRenderedIds = newIds
            uiView.reloadData()
        }

        if editModeChanged {
            context.coordinator.applyEditMode(to: uiView, enabled: isEditMode)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            items: $items,
            boxModel: boxModel,
            isEditMode: $isEditMode,
            isDragging: $isDragging,
            onScroll: onScroll
        )
    }

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        @Binding var items: [AppSubCache]
        let boxModel: BoxJsViewModel
        @Binding var isEditMode: Bool
        @Binding var isDragging: Bool
        var onScroll: ((CGFloat) -> Void)?
        weak var collectionView: UICollectionView?
        weak var reorderLongPressGesture: UILongPressGestureRecognizer?
        var lastRenderedIds: [String] = []
        var previousEditMode: Bool = false

        init(
            items: Binding<[AppSubCache]>,
            boxModel: BoxJsViewModel,
            isEditMode: Binding<Bool>,
            isDragging: Binding<Bool>,
            onScroll: ((CGFloat) -> Void)?
        ) {
            _items = items
            self.boxModel = boxModel
            _isEditMode = isEditMode
            _isDragging = isDragging
            self.onScroll = onScroll
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(-scrollView.contentOffset.y)
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            items.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubCardCell", for: indexPath) as! SubCardCell
            let item = items[indexPath.item]
            cell.configure(with: item)
            cell.showDeleteBadge(isEditMode)
            cell.onDelete = { [weak self] in
                guard let self, let url = self.items[indexPath.item].url else { return }
                Task {
                    await self.boxModel.deleteAppSub(url: url)
                }
            }
            if isEditMode {
                startJiggleAnimation(for: cell)
            } else {
                cell.layer.removeAnimation(forKey: "jiggle.rotation")
                cell.layer.removeAnimation(forKey: "jiggle.bounce")
                cell.transform = .identity
            }
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let spacing: CGFloat = 12
            let inset: CGFloat = 32
            let width = (collectionView.bounds.width - inset - spacing) / 2
            return CGSize(width: floor(width), height: 112)
        }

        // jiggle 模式下禁止 cell 选中
        func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
            return !isEditMode
        }

        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            Task {
                await boxModel.reloadAppSub(url: "")
                await MainActor.run {
                    refreshControl.endRefreshing()
                }
            }
        }

        // 点击任意位置退出 jiggle 模式
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let collectionView = collectionView, isEditMode else { return }
            isEditMode = false
            applyEditMode(to: collectionView, enabled: false)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let collectionView = collectionView else { return }
            guard isEditMode else { return }
            let location = gesture.location(in: collectionView)

            switch gesture.state {
            case .began:
                guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
                isDragging = true
                collectionView.beginInteractiveMovementForItem(at: indexPath)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

            case .changed:
                if isDragging {
                    collectionView.updateInteractiveMovementTargetPosition(location)
                }

            case .ended:
                if isDragging {
                    isDragging = false
                    collectionView.endInteractiveMovement()
                }

            default:
                if isDragging {
                    isDragging = false
                    collectionView.cancelInteractiveMovement()
                }
            }
        }

        // MARK: - 原生 Context Menu（静止长按弹出 iOS 风格深色菜单）

        func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            guard !isEditMode, indexPath.item < items.count else { return nil }
            let item = items[indexPath.item]

            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { [weak self] _ in
                guard let self else { return nil }

                let editAction = UIAction(
                    title: "编辑模式",
                    image: UIImage(systemName: "square.grid.3x3.topleft.filled")
                ) { [weak self] _ in
                    guard let self else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    self.isEditMode = true
                    self.applyEditMode(to: collectionView, enabled: true)
                }

                let refreshAction = UIAction(
                    title: "刷新订阅",
                    image: UIImage(systemName: "arrow.clockwise")
                ) { [weak self] _ in
                    guard let self, let url = item.url else { return }
                    Task { await self.boxModel.reloadAppSub(url: url) }
                }

                let deleteAction = UIAction(
                    title: "删除订阅",
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [weak self] _ in
                    guard let self, let url = item.url else { return }
                    Task { await self.boxModel.deleteAppSub(url: url) }
                }

                return UIMenu(title: "", children: [editAction, refreshAction, deleteAction])
            }
        }

        func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            makeCardTargetedPreview(collectionView: collectionView, configuration: configuration)
        }

        func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            makeCardTargetedPreview(collectionView: collectionView, configuration: configuration)
        }

        private func makeCardTargetedPreview(collectionView: UICollectionView, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let indexPath = configuration.identifier as? IndexPath,
                  let cell = collectionView.cellForItem(at: indexPath) as? SubCardCell else {
                return nil
            }

            let parameters = cell.makeContextMenuPreviewParameters()
            return UITargetedPreview(view: cell.contextMenuPreviewView, parameters: parameters)
        }

        func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
            true
        }

        func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            let movedItem = items.remove(at: sourceIndexPath.item)
            items.insert(movedItem, at: destinationIndexPath.item)
            persistOrder()
        }

        private func persistOrder() {
            let subs = boxModel.boxData.appsubs
            let reorderedData = items.compactMap { ordered in
                subs.first { $0.url == ordered.url }
            }.map { ["url": $0.url, "enable": $0.enable, "id": $0.id ?? ""] as [String: Any] }
            boxModel.updateData(path: "usercfgs.appsubs", data: reorderedData)
        }

        // MARK: - Jiggle Animation

        func applyEditMode(to collectionView: UICollectionView, enabled: Bool) {
            for cell in collectionView.visibleCells {
                if let subCell = cell as? SubCardCell {
                    subCell.showDeleteBadge(enabled)
                }
                if enabled {
                    startJiggleAnimation(for: cell)
                } else {
                    cell.layer.removeAnimation(forKey: "jiggle.rotation")
                    cell.layer.removeAnimation(forKey: "jiggle.bounce")
                    cell.transform = .identity
                }
            }
        }

        func startJiggleAnimation(for cell: UICollectionViewCell) {
            // 旋转动画（带随机相位偏移，模拟真实 iOS 每个 icon 节奏不同）
            let variance = Double.random(in: -0.025...0.025)
            let rotateDuration = 0.14 + variance
            let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotation.values = [-0.02, 0.02]
            rotation.autoreverses = true
            rotation.duration = rotateDuration
            rotation.repeatCount = .infinity
            rotation.isRemovedOnCompletion = false

            // 纵向 bounce 动画（iOS 真实 jiggle 的标志性上下弹动）
            let bounceDuration = 0.18 + variance
            let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
            bounce.values = [2.0, 0.0]
            bounce.autoreverses = true
            bounce.duration = bounceDuration
            bounce.repeatCount = .infinity
            bounce.isRemovedOnCompletion = false

            cell.layer.add(rotation, forKey: "jiggle.rotation")
            cell.layer.add(bounce, forKey: "jiggle.bounce")
        }
    }
}

// MARK: - SubCardCell

final class SubCardCell: UICollectionViewCell {
    private let cardView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let countLabel = UILabel()
    private let errorBadge = UILabel()
    private let deleteButton = UIButton(type: .custom)

    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.clipsToBounds = false
        clipsToBounds = false

        // Card background
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 18
        iconView.backgroundColor = .systemGray5

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        countLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        errorBadge.text = "异常"
        errorBadge.font = .systemFont(ofSize: 10, weight: .medium)
        errorBadge.textColor = .white
        errorBadge.backgroundColor = .systemRed
        errorBadge.layer.cornerRadius = 8
        errorBadge.layer.masksToBounds = true
        errorBadge.textAlignment = .center
        errorBadge.isHidden = true

        [titleLabel, iconView, timeLabel, countLabel, errorBadge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        // Delete button - sits outside card, on contentView
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.white, .darkGray]))
        deleteButton.setImage(UIImage(systemName: "minus.circle.fill", withConfiguration: config), for: .normal)
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -8),

            iconView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            errorBadge.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            errorBadge.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -6),
            errorBadge.widthAnchor.constraint(equalToConstant: 34),
            errorBadge.heightAnchor.constraint(equalToConstant: 16),

            timeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            timeLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            countLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            countLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),

            deleteButton.centerXAnchor.constraint(equalTo: cardView.leadingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: cardView.topAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    func configure(with item: AppSubCache) {
        titleLabel.text = item.name
        timeLabel.text = item.updateTime.isEmpty ? "N/A" : item.formatTime
        countLabel.text = "\(item.apps.count)"
        errorBadge.isHidden = item.isErr != true

        if let url = URL(string: item.icon), !item.icon.isEmpty {
            iconView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "shippingbox.fill"))
        } else {
            iconView.image = UIImage(systemName: "shippingbox.fill")
            iconView.tintColor = .systemGray3
        }
    }

    func showDeleteBadge(_ show: Bool) {
        deleteButton.isHidden = !show
    }

    var contextMenuPreviewView: UIView {
        cardView
    }

    func makeContextMenuPreviewParameters() -> UIPreviewParameters {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.visiblePath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        )
        return parameters
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    SubcribeView()
}
