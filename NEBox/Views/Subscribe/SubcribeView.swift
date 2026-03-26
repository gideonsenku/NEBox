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
    @State private var items: [AppSubCache] = []
    @State private var isEditMode: Bool = false
    @State private var isDragging: Bool = false
    @State private var showAddAlert: Bool = false
    @State private var addUrlInput: String = ""
    @State private var selectedSub: AppSubCache? = nil
    @State private var isNavActive: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Gradient background — matches HomeView
                LinearGradient(
                    colors: [Color(hex: "#EEF0FA"), Color(hex: "#F0EDF8"), Color(hex: "#F5F0F8")],
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
                            onTap: { sub in
                                selectedSub = sub
                                isNavActive = true
                            }
                        )
                        .ignoresSafeArea(edges: .bottom)
                    }
                }

                // Nav bar always on top — solid background covers scrolled cells
                VStack {
                    navBar
                        .background(Color(hex: "#EEF0FA").ignoresSafeArea())
                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isNavActive) {
                SubDetailView(sub: selectedSub)
            }
        }
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
        .onReceive(boxModel.$boxData) { data in
            if !isDragging {
                items = data.displayAppSubs
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
                        .fill(Color(hex: "#E8EAF4"))
                        .frame(width: 36, height: 36)
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#002FA7"))
                }
                Text("应用订阅")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1918"))
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
                            .foregroundColor(Color(hex: "#002FA7"))
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
                        .foregroundColor(Color(hex: "#002FA7"))
                }
                Button {
                    addUrlInput = ""
                    showAddAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: "#002FA7"))
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
                    .fill(Color(hex: "#ECEEF4"))
                    .frame(width: 80, height: 80)
                Image(systemName: "tray")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "#9098AD"))
            }
            VStack(spacing: 8) {
                Text("暂无订阅")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1918"))
                Text("添加订阅源后，这里会展示所有应用")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6D6C6A"))
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
                .background(Color(hex: "#002FA7"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Collection View Wrapper

struct SubCollectionViewWrapper: UIViewRepresentable {
    @Binding var items: [AppSubCache]
    let boxModel: BoxJsViewModel
    @Binding var isEditMode: Bool
    @Binding var isDragging: Bool
    var onTap: ((AppSubCache) -> Void)? = nil

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 110, right: 20)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.clipsToBounds = false
        cv.delegate = context.coordinator
        cv.dataSource = context.coordinator
        cv.register(SubCardCell.self, forCellWithReuseIdentifier: "SubCardCell")

        context.coordinator.collectionView = cv

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
        let newIds = items.map { $0.id }
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
            if needsReload { uiView.reloadData() }
            if editChanged { coord.applyEditMode(to: uiView, enabled: isEditMode) }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, boxModel: boxModel, isEditMode: $isEditMode, isDragging: $isDragging, onTap: onTap)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        @Binding var items: [AppSubCache]
        let boxModel: BoxJsViewModel
        @Binding var isEditMode: Bool
        @Binding var isDragging: Bool
        var onTap: ((AppSubCache) -> Void)?
        weak var collectionView: UICollectionView?
        weak var reorderGesture: UILongPressGestureRecognizer?
        var lastRenderedIds: [String] = []
        var lastFingerprint: [String] = []
        var prevEditMode: Bool = false
        private var refreshTimer: Timer?

        init(items: Binding<[AppSubCache]>, boxModel: BoxJsViewModel, isEditMode: Binding<Bool>, isDragging: Binding<Bool>, onTap: ((AppSubCache) -> Void)?) {
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
                    guard let urlString = item.url, let url = URL(string: urlString) else { return }
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

        private func cardPreview(cv: UICollectionView, config: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let ip = config.identifier as? IndexPath,
                  let cell = cv.cellForItem(at: ip) as? SubCardCell else { return nil }
            let params = UIPreviewParameters()
            params.backgroundColor = .clear
            params.visiblePath = UIBezierPath(roundedRect: cell.cardView.bounds, cornerRadius: cell.cardView.layer.cornerRadius)
            return UITargetedPreview(view: cell.cardView, parameters: params)
        }

        // MARK: Refresh

        @objc func handleRefresh(_ rc: UIRefreshControl) {
            Task {
                await boxModel.reloadAllAppSub()
                await MainActor.run { rc.endRefreshing() }
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
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        // Border
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(red: 229/255, green: 228/255, blue: 225/255, alpha: 1).cgColor
        // Shadow
        cardView.layer.shadowColor = UIColor(red: 26/255, green: 25/255, blue: 24/255, alpha: 1).cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.031  // ~3% (hex 08 = 8/255)
        cardView.layer.shadowRadius = 5
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Avatar — 40pt circle
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 20
        avatarView.backgroundColor = UIColor(red: 236/255, green: 238/255, blue: 244/255, alpha: 1)
        avatarView.tintColor = UIColor(red: 144/255, green: 152/255, blue: 173/255, alpha: 1)
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = UIColor(red: 26/255, green: 25/255, blue: 24/255, alpha: 1)
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Date
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = UIColor(red: 156/255, green: 155/255, blue: 153/255, alpha: 1)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        // Count
        countLabel.font = .systemFont(ofSize: 22, weight: .bold)
        countLabel.textColor = UIColor(red: 26/255, green: 25/255, blue: 24/255, alpha: 1)
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

    func configure(with item: AppSubCache) {
        nameLabel.text = item.name
        dateLabel.text = item.updateTime.isEmpty ? "--" : item.formatTime
        countLabel.text = "\(item.apps.count)"

        if !item.icon.isEmpty, let url = URL(string: item.icon) {
            avatarView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "shippingbox"))
        } else {
            avatarView.image = UIImage(systemName: "shippingbox")
        }
    }

    func showDeleteBadge(_ show: Bool) { deleteButton.isHidden = !show }

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
