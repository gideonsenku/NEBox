//
//  SubcribeView.swift
//  NEBox
//

import SwiftUI
import UIKit
import SDWebImage

struct SubcribeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @State private var items: [AppSubSummary] = []
    @State private var isEditMode: Bool = false
    @State private var isDragging: Bool = false
    @State private var showAddAlert: Bool = false
    @State private var addUrlInput: String = ""
    @State private var selectedSubURL: String? = nil
    @State private var isNavActive: Bool = false

    var body: some View {
        neboxNavigationContainer {
            ZStack(alignment: .top) {
                // Gradient background — matches HomeView
                LinearGradient(
                    colors: Color.pageGradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Placeholder to push content below nav bar
                    Color.clear.frame(height: 56)

                    if items.isEmpty {
                        emptyState
                    } else {
                        SubCollectionViewWrapper(
                            items: $items,
                            boxModel: boxModel,
                            isEditMode: $isEditMode,
                            isDragging: $isDragging,
                            onTap: { summary in
                                selectedSubURL = summary.url
                                isNavActive = true
                            }
                        )
                        .ignoresSafeArea(edges: .bottom)
                    }
                }

                // Nav bar always on top — solid background covers scrolled cells
                VStack {
                    navBar
                        .background(Color.gradientTop.ignoresSafeArea())
                    Spacer()
                }
            }
            .neboxHiddenNavigationBar()
            .neboxNavigationDestination(isPresented: $isNavActive) {
                SubDetailView(subURL: selectedSubURL)
            }
        }
        .neboxLiquidGlassTabBarChrome()
        .alert("添加订阅", isPresented: $showAddAlert) {
            TextField("输入订阅地址", text: $addUrlInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("确定") {
                let url = addUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.isEmpty {
                    Task { await boxModel.addAppSub(url: url) }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .onReceive(boxModel.$cachedAppSubSummaries) { summaries in
            if !isDragging {
                items = summaries
            }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 0) {
            // Left: page identity (mirrors HomeView's tool switcher position)
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bgMuted)
                        .frame(width: 36, height: 36)
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accent)
                }
                Text("应用订阅")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            // Right: actions
            HStack(spacing: 16) {
                if !items.isEmpty {
                    Button {
                        isEditMode.toggle()
                    } label: {
                        Text(isEditMode ? "完成" : "编辑")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.accent)
                    }
                }
                Button {
                    Task {
                        await boxModel.reloadAllAppSub()
                        toastManager.showToast(message: "已刷新全部订阅")
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accent)
                }
                Button {
                    addUrlInput = ""
                    showAddAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.accent)
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.bgMuted)
                    .frame(width: 80, height: 80)
                Image(systemName: "tray")
                    .font(.system(size: 36))
                    .foregroundColor(.textTertiary)
            }
            VStack(spacing: 8) {
                Text("暂无订阅")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("添加订阅源后，这里会展示所有应用")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                addUrlInput = ""
                showAddAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("添加订阅")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .frame(height: 48)
                .background(Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Collection View Wrapper

struct SubCollectionViewWrapper: UIViewRepresentable {
    @Binding var items: [AppSubSummary]
    let boxModel: BoxJsViewModel
    @Binding var isEditMode: Bool
    @Binding var isDragging: Bool
    var onTap: ((AppSubSummary) -> Void)? = nil

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: adaptiveBottomInset(), right: 20)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.clipsToBounds = false
        cv.delegate = context.coordinator
        cv.dataSource = context.coordinator
        cv.register(SubCardCell.self, forCellWithReuseIdentifier: "SubCardCell")

        context.coordinator.collectionView = cv

        // Allow navigation swipe back gesture
        context.coordinator.setupEdgeSwipeSupport(for: cv)

        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(context.coordinator.handleRefresh(_:)), for: .valueChanged)
        cv.refreshControl = refresh

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.18
        longPress.isEnabled = false
        cv.addGestureRecognizer(longPress)
        context.coordinator.reorderGesture = longPress

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        cv.addGestureRecognizer(tap)

        return cv
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let coord = context.coordinator
        let prevIds = coord.lastRenderedIds
        let newIds = items.map(\.id)
        let newFingerprint = items.map { $0.id + $0.updateTime }
        let editChanged = coord.prevEditMode != isEditMode

        // Only update non-binding properties; @Binding already reflects parent state
        coord.onTap = onTap
        coord.prevEditMode = isEditMode
        coord.reorderGesture?.isEnabled = isEditMode

        let needsReload = !isDragging && (prevIds != newIds || coord.lastFingerprint != newFingerprint)
        if needsReload {
            coord.lastRenderedIds = newIds
            coord.lastFingerprint = newFingerprint
        }
        DispatchQueue.main.async {
            if needsReload {
                if uiView.refreshControl?.isRefreshing == true {
                    coord.needsReloadAfterRefresh = true
                } else {
                    uiView.reloadData()
                }
            }
            if editChanged { coord.applyEditMode(to: uiView, enabled: isEditMode) }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, boxModel: boxModel, isEditMode: $isEditMode, isDragging: $isDragging, onTap: onTap)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        @Binding var items: [AppSubSummary]
        let boxModel: BoxJsViewModel
        @Binding var isEditMode: Bool
        @Binding var isDragging: Bool
        var onTap: ((AppSubSummary) -> Void)?
        weak var collectionView: UICollectionView?
        weak var reorderGesture: UILongPressGestureRecognizer?
        var lastRenderedIds: [String] = []
        var lastFingerprint: [String] = []
        var prevEditMode: Bool = false
        var needsReloadAfterRefresh = false
        private var refreshTimer: Timer?

        init(items: Binding<[AppSubSummary]>, boxModel: BoxJsViewModel, isEditMode: Binding<Bool>, isDragging: Binding<Bool>, onTap: ((AppSubSummary) -> Void)?) {
            _items = items
            self.boxModel = boxModel
            _isEditMode = isEditMode
            _isDragging = isDragging
            self.onTap = onTap
            super.init()
            startRefreshTimer()
        }

        deinit {
            refreshTimer?.invalidate()
        }

        private func startRefreshTimer() {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                guard let self, let cv = self.collectionView else { return }
                for cell in cv.visibleCells {
                    guard let ip = cv.indexPath(for: cell),
                          ip.item < self.items.count,
                          let subCell = cell as? SubCardCell else { continue }
                    subCell.configure(with: self.items[ip.item])
                }
            }
        }

        /// Configure collection view's pan gesture to allow navigation back swipe from left edge
        func setupEdgeSwipeSupport(for collectionView: UICollectionView) {
            var responder: UIResponder? = collectionView
            while let next = responder?.next {
                if let nav = next as? UINavigationController,
                   let popGesture = nav.interactivePopGestureRecognizer {
                    collectionView.panGestureRecognizer.require(toFail: popGesture)
                    popGesture.isEnabled = true
                    popGesture.delegate = nil
                    break
                }
                responder = next
            }
        }

        func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int { items.count }

        func collectionView(_ cv: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
            let inset: CGFloat = 40   // left 20 + right 20
            let gap: CGFloat = 12
            let width = floor((cv.bounds.width - inset - gap) / 2)
            return CGSize(width: width, height: 128)
        }

        func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "SubCardCell", for: indexPath) as! SubCardCell
            let item = items[indexPath.item]
            cell.resetAppearance()
            cell.configure(with: item)
            cell.showDeleteBadge(isEditMode)
            cell.onDelete = { [weak self] in
                guard let self, let url = self.items[safe: indexPath.item]?.url else { return }
                Task { await self.boxModel.deleteAppSub(url: url) }
            }
            if isEditMode { startJiggle(for: cell) }
            else { stopJiggle(for: cell) }
            return cell
        }

        func collectionView(_: UICollectionView, shouldSelectItemAt _: IndexPath) -> Bool { !isEditMode }

        func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard !isEditMode, indexPath.item < items.count else { return }
            onTap?(items[indexPath.item])
        }

        // MARK: Context Menu

        func collectionView(_ cv: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            guard !isEditMode, indexPath.item < items.count else { return nil }
            let item = items[indexPath.item]

            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { [weak self] _ in
                guard let self else { return nil }

                let refresh = UIAction(title: "刷新", image: UIImage(systemName: "arrow.clockwise")) { [weak self] _ in
                    guard let url = item.url else { return }
                    Task { await self?.boxModel.reloadAppSub(url: url) }
                }

                let openInBrowser = UIAction(title: "在浏览器中打开", image: UIImage(systemName: "safari")) { _ in
                    guard let url = URL(string: item.repo) else { return }
                    UIApplication.shared.open(url)
                }

                let copyURL = UIAction(title: "复制订阅 URL", image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = item.url
                }

                let delete = UIAction(title: "删除订阅", image: UIImage(systemName: "minus.circle"), attributes: .destructive) { [weak self] _ in
                    guard let url = item.url else { return }
                    Task { await self?.boxModel.deleteAppSub(url: url) }
                }

                return UIMenu(title: "", children: [refresh, openInBrowser, copyURL, delete])
            }
        }

        func collectionView(_ cv: UICollectionView, previewForHighlightingContextMenuWithConfiguration config: UIContextMenuConfiguration) -> UITargetedPreview? {
            cardPreview(cv: cv, config: config)
        }

        func collectionView(_ cv: UICollectionView, previewForDismissingContextMenuWithConfiguration config: UIContextMenuConfiguration) -> UITargetedPreview? {
            cardPreview(cv: cv, config: config)
        }

        func collectionView(_ cv: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            guard let ip = configuration.identifier as? IndexPath,
                  let cell = cv.cellForItem(at: ip) as? SubCardCell else { return }
            animator?.addCompletion {
                cell.resetAppearance()
            }
            cell.resetAppearance()
        }

        private func cardPreview(cv: UICollectionView, config: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let ip = config.identifier as? IndexPath,
                  let cell = cv.cellForItem(at: ip) as? SubCardCell else { return nil }

            // Use a snapshot for context menu preview to avoid UIKit mutating the live card view
            // (which can cause temporary transparent/background-loss artifacts after cancellation).
            guard let snapshot = cell.cardView.snapshotView(afterScreenUpdates: false) else { return nil }
            snapshot.frame = cell.cardView.bounds
            snapshot.layer.cornerRadius = cell.cardView.layer.cornerRadius
            snapshot.layer.cornerCurve = cell.cardView.layer.cornerCurve
            snapshot.layer.masksToBounds = true

            let params = UIPreviewParameters()
            params.backgroundColor = .clear
            params.visiblePath = UIBezierPath(roundedRect: cell.cardView.bounds, cornerRadius: cell.cardView.layer.cornerRadius)
            let target = UIPreviewTarget(
                container: cell.contentView,
                center: CGPoint(x: cell.cardView.frame.midX, y: cell.cardView.frame.midY)
            )
            return UITargetedPreview(view: snapshot, parameters: params, target: target)
        }

        // MARK: Refresh

        @objc func handleRefresh(_ rc: UIRefreshControl) {
            Task {
                await boxModel.reloadAllAppSub()
                await MainActor.run {
                    rc.endRefreshing()
                    if needsReloadAfterRefresh, let cv = collectionView {
                        needsReloadAfterRefresh = false
                        cv.reloadData()
                    }
                }
            }
        }

        // MARK: Tap (exit edit mode)

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let cv = collectionView, isEditMode else { return }
            isEditMode = false
            applyEditMode(to: cv, enabled: false)
        }

        // MARK: Long Press (reorder in edit mode)

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let cv = collectionView, isEditMode else { return }
            let loc = gesture.location(in: cv)
            switch gesture.state {
            case .began:
                guard let ip = cv.indexPathForItem(at: loc) else { return }
                isDragging = true
                cv.beginInteractiveMovementForItem(at: ip)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .changed:
                if isDragging { cv.updateInteractiveMovementTargetPosition(loc) }
            case .ended:
                if isDragging { isDragging = false; cv.endInteractiveMovement() }
            default:
                if isDragging { isDragging = false; cv.cancelInteractiveMovement() }
            }
        }

        // MARK: Reorder

        func collectionView(_: UICollectionView, canMoveItemAt _: IndexPath) -> Bool { true }

        func collectionView(_: UICollectionView, moveItemAt src: IndexPath, to dst: IndexPath) {
            let moved = items.remove(at: src.item)
            items.insert(moved, at: dst.item)
            let subs = boxModel.boxData.appsubs
            let reordered = items.compactMap { ordered in subs.first { $0.url == ordered.url } }
                .map { ["url": $0.url, "enable": $0.enable, "id": $0.id ?? ""] as [String: Any] }
            Task { @MainActor in
                boxModel.updateData(path: "usercfgs.appsubs", data: reordered)
            }
        }

        // MARK: Jiggle

        func applyEditMode(to cv: UICollectionView, enabled: Bool) {
            for cell in cv.visibleCells {
                (cell as? SubCardCell)?.showDeleteBadge(enabled)
                if enabled { startJiggle(for: cell) } else { stopJiggle(for: cell) }
            }
        }

        func startJiggle(for cell: UICollectionViewCell) {
            let v = Double.random(in: -0.025...0.025)
            let rot = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rot.values = [-0.02, 0.02]; rot.autoreverses = true
            rot.duration = 0.14 + v; rot.repeatCount = .infinity; rot.isRemovedOnCompletion = false
            let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
            bounce.values = [2.0, 0.0]; bounce.autoreverses = true
            bounce.duration = 0.18 + v; bounce.repeatCount = .infinity; bounce.isRemovedOnCompletion = false
            cell.layer.add(rot, forKey: "jiggle.rotation")
            cell.layer.add(bounce, forKey: "jiggle.bounce")
        }

        func stopJiggle(for cell: UICollectionViewCell) {
            cell.layer.removeAnimation(forKey: "jiggle.rotation")
            cell.layer.removeAnimation(forKey: "jiggle.bounce")
            cell.transform = .identity
        }
    }
}

// MARK: - SubCardCell

final class SubCardCell: UICollectionViewCell {
    let cardView = UIView()
    private static var cardBorderColor: CGColor { UIColor(.borderSubtle).cgColor }
    private let nameLabel = UILabel()
    private let avatarView = UIImageView()
    private let dateLabel = UILabel()
    private let countLabel = UILabel()
    private let deleteButton = UIButton(type: .custom)

    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        setupCard()
    }

    private func setupCard() {
        // Card
        resetAppearance()
        // Shadow
        cardView.layer.shadowColor = UIColor(.textPrimary).cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.031  // ~3% (hex 08 = 8/255)
        cardView.layer.shadowRadius = 5
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Avatar — 40pt circle
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 20
        avatarView.backgroundColor = UIColor(.bgMuted)
        avatarView.tintColor = UIColor(.textTertiary)
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = UIColor(.textPrimary)
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Date
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = UIColor(.textTertiary)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        // Count
        countLabel.font = .systemFont(ofSize: 22, weight: .bold)
        countLabel.textColor = UIColor(.textPrimary)
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        [avatarView, nameLabel, dateLabel, countLabel].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Avatar: top-right, 40×40
            avatarView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            avatarView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            // Name: top-left, right of avatar
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: avatarView.leadingAnchor, constant: -8),

            // Date: bottom-left
            dateLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            dateLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            // Count: bottom-right
            countLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            countLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
        ])

        // Delete badge: top-left of card
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.white, .darkGray]))
        deleteButton.setImage(UIImage(systemName: "minus.circle.fill", withConfiguration: config), for: .normal)
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: cardView.leadingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: cardView.topAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    private lazy var fallbackLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor(.textSecondary)
        if let descriptor = UIFont.systemFont(ofSize: 40 * 0.42, weight: .semibold)
            .fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            label.font = .systemFont(ofSize: 40 * 0.42, weight: .semibold)
        }
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
        ])
        return label
    }()

    func configure(with item: AppSubSummary) {
        nameLabel.text = item.name
        dateLabel.text = item.updateTime.isEmpty ? "--" : formattedTimeDifference(from: item.updateTime)
        countLabel.text = "\(item.appCount)"

        if !item.icon.isEmpty, let url = URL(string: item.icon) {
            // Downsample to display size (40pt × @3x = 120px) to avoid decoding
            // full-resolution bitmaps (e.g. 1024×1024 → 4MB each) into memory.
            let thumbSize = CGSize(width: 120, height: 120)
            avatarView.sd_setImage(with: url, placeholderImage: nil, options: [], context: [.imageThumbnailPixelSize: thumbSize], progress: nil) { [weak self] image, _, _, _ in
                guard let self else { return }
                if image == nil {
                    self.showFallbackLabel(for: item.name)
                } else {
                    self.fallbackLabel.isHidden = true
                }
            }
        } else {
            showFallbackLabel(for: item.name)
        }
    }

    private func showFallbackLabel(for name: String) {
        avatarView.image = nil
        avatarView.backgroundColor = UIColor(.bgMuted)
        fallbackLabel.text = name.first.map(String.init)
        fallbackLabel.isHidden = false
    }

    func showDeleteBadge(_ show: Bool) { deleteButton.isHidden = !show }

    func resetAppearance() {
        cardView.backgroundColor = UIColor(.bgCard)
        cardView.alpha = 1
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Self.cardBorderColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            cardView.layer.borderColor = Self.cardBorderColor
            cardView.layer.shadowColor = UIColor(.textPrimary).cgColor
        }
    }

    @objc private func deleteTapped() { onDelete?() }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    SubcribeView()
}
