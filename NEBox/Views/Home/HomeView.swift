import SwiftUI
import UIKit
import SDWebImageSwiftUI
import os.log

private let homeLog = Logger(subsystem: "NEBox", category: "HomeView")

/// Fallback icon URL derived from env id
private func fallbackIconURL(for envId: String) -> String {
    let key = envId.lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
    return "https://raw.githubusercontent.com/Orz-3/mini/master/Color/\(key).png"
}

/// Best icon URL for a SysEnv: prefer Color icon (index 1), then first, then fallback
private func iconURL(for env: SysEnv) -> String {
    if let icons = env.icons {
        if icons.count > 1, !icons[1].isEmpty { return icons[1] }
        if let first = icons.first, !first.isEmpty { return first }
    }
    return fallbackIconURL(for: env.id)
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @Binding var showSearch: Bool

    @State var items: [AppModel] = []
    @State private var selectedApp: AppModel? = nil
    @State private var isNavigationActive: Bool = false
    @State private var isEditMode: Bool = false

    private var activeEnv: String? { boxModel.boxData.syscfgs?.env }
    private var availableEnvs: [SysEnv] { boxModel.boxData.syscfgs?.envs ?? [] }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "#EEF0FA"), Color(hex: "#F0EDF8"), Color(hex: "#F5F0F8")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    navBar

                    if !boxModel.isDataLoaded {
                        Spacer()
                        ProgressView().scaleEffect(1.2)
                        Spacer()
                    } else if !boxModel.favApps.isEmpty {
                        CollectionViewWrapper(
                            items: $items,
                            boxModel: boxModel,
                            selectedApp: $selectedApp,
                            isNavigationActive: $isNavigationActive,
                            isEditMode: $isEditMode
                        )
                    } else {
                        emptyStateView
                    }
                }
                .onAppear { items = boxModel.favApps }
                .onReceive(boxModel.$boxData) { data in
                    items = data.favApps
                }

            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isNavigationActive) {
                AppDetailView(app: selectedApp)
            }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 0) {
            // Left: current tool indicator (read-only)
            toolAvatarView
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Spacer()

            // Right: edit / search
            HStack(spacing: 16) {
                if !boxModel.favApps.isEmpty {
                    Button {
                        isEditMode.toggle()
                    } label: {
                        Text(isEditMode ? "完成" : "编辑")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#002FA7"))
                    }
                }
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: "#002FA7"))
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var toolAvatarView: some View {
        if let envId = activeEnv, !envId.isEmpty {
            let urlString: String = {
                if let sysEnv = availableEnvs.first(where: { $0.id == envId }) {
                    return iconURL(for: sysEnv)
                }
                return fallbackIconURL(for: envId)
            }()
            WebImage(url: URL(string: urlString)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Text(envId.prefix(1))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#002FA7"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#EEF0FA"))
            }
        } else {
            Image(systemName: "network")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#9098AD"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#EEF0FA"))
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#5A6177").opacity(0.4))
            Text("还没有收藏应用")
                .foregroundColor(Color(hex: "#5A6177").opacity(0.7))
            Button {
                showSearch = true
            } label: {
                Text("搜索并添加")
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#002FA7"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
    }

}

// MARK: - CollectionViewWrapper

struct CollectionViewWrapper: UIViewRepresentable {
    @Binding var items: [AppModel]
    var boxModel: BoxJsViewModel
    @Binding var selectedApp: AppModel?
    @Binding var isNavigationActive: Bool
    @Binding var isEditMode: Bool
    var bottomInset: CGFloat = 110
    var allowsEdit: Bool = true
    var tapOverride: ((AppModel) -> Void)? = nil
    var favAppIds: Set<String> = []

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 24, left: 16, bottom: bottomInset, right: 16)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 24

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.register(MyCell.self, forCellWithReuseIdentifier: "Cell")

        context.coordinator.collectionView = collectionView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(context.coordinator.handleRefresh(_:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let coord = context.coordinator
        let editModeChanged = isEditMode != coord.prevEditMode
        // Only update non-binding properties; @Binding already reflects parent state
        coord.tapOverride = tapOverride
        coord.favAppIds = favAppIds
        coord.prevEditMode = isEditMode
        DispatchQueue.main.async {
            uiView.reloadData()
            if editModeChanged {
                coord.applyJiggle(to: uiView, enabled: isEditMode)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, boxModel: boxModel, selectedApp: $selectedApp, isNavigationActive: $isNavigationActive, isEditMode: $isEditMode, allowsEdit: allowsEdit, tapOverride: tapOverride, favAppIds: favAppIds)
    }

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        @Binding var items: [AppModel]
        var boxModel: BoxJsViewModel
        @Binding var selectedApp: AppModel?
        @Binding var isNavigationActive: Bool
        @Binding var isEditMode: Bool
        var allowsEdit: Bool
        var tapOverride: ((AppModel) -> Void)?
        var favAppIds: Set<String>
        var prevEditMode: Bool = false
        weak var collectionView: UICollectionView?

        init(items: Binding<[AppModel]>, boxModel: BoxJsViewModel, selectedApp: Binding<AppModel?>, isNavigationActive: Binding<Bool>, isEditMode: Binding<Bool>, allowsEdit: Bool, tapOverride: ((AppModel) -> Void)?, favAppIds: Set<String>) {
            _items = items
            self.boxModel = boxModel
            _selectedApp = selectedApp
            _isNavigationActive = isNavigationActive
            _isEditMode = isEditMode
            self.allowsEdit = allowsEdit
            self.tapOverride = tapOverride
            self.favAppIds = favAppIds
        }

        func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int { items.count }

        func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
            let columns: CGFloat = 4
            let totalInset: CGFloat = 32
            let width = floor((collectionView.bounds.width - totalInset) / columns)
            return CGSize(width: width, height: 90)
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCell
            let app = items[indexPath.item]
            cell.titleLabel.text = app.name
            if let str = app.icon, let url = URL(string: str) {
                cell.imageURL = url
            } else {
                cell.imageView.image = UIImage(systemName: "placeholdertext.fill")
            }
            cell.showDeleteBadge(allowsEdit && isEditMode)
            cell.showFavBadge(!favAppIds.isEmpty && favAppIds.contains(app.id))
            if allowsEdit && isEditMode { startJiggleAnimation(for: cell) }
            else { cell.layer.removeAnimation(forKey: "jiggle"); cell.transform = .identity }
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let app = items[indexPath.item]
            if let tapOverride {
                tapOverride(app)
            } else if isEditMode {
                let updateIds = items.map { $0.id }.filter { $0 != app.id }
                Task { @MainActor in
                    boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
                }
            } else {
                Task { @MainActor in
                    selectedApp = app
                    isNavigationActive = true
                }
            }
        }

        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            boxModel.fetchData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { refreshControl.endRefreshing() }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard allowsEdit, let collectionView else { return }
            switch gesture.state {
            case .began:
                if !isEditMode {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isEditMode = true
                    applyJiggle(to: collectionView, enabled: true)
                    updateDeleteBadges(in: collectionView, show: true)
                }
                if let ip = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) {
                    collectionView.beginInteractiveMovementForItem(at: ip)
                }
            case .changed:
                collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            case .ended:
                collectionView.endInteractiveMovement()
            default:
                collectionView.cancelInteractiveMovement()
            }
        }

        func applyJiggle(to collectionView: UICollectionView, enabled: Bool) {
            for cell in collectionView.visibleCells {
                if enabled { startJiggleAnimation(for: cell) }
                else { cell.layer.removeAnimation(forKey: "jiggle"); cell.transform = .identity }
            }
        }

        func startJiggleAnimation(for cell: UICollectionViewCell) {
            let angle: CGFloat = .pi / 90
            let anim = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            anim.values = [-angle, angle, -angle]
            anim.keyTimes = [0, 0.5, 1.0]
            anim.duration = 0.25 + Double.random(in: 0...0.08)
            anim.repeatCount = .infinity
            anim.isRemovedOnCompletion = false
            cell.layer.add(anim, forKey: "jiggle")
        }

        func updateDeleteBadges(in collectionView: UICollectionView, show: Bool) {
            for cell in collectionView.visibleCells {
                (cell as? MyCell)?.showDeleteBadge(show)
            }
        }

        func collectionView(_: UICollectionView, canMoveItemAt _: IndexPath) -> Bool { true }

        func collectionView(_: UICollectionView, moveItemAt src: IndexPath, to dst: IndexPath) {
            let moved = items.remove(at: src.item)
            items.insert(moved, at: dst.item)
            let ids = items.map { $0.id }
            Task { @MainActor in
                boxModel.updateData(path: "usercfgs.favapps", data: ids)
            }
        }
    }
}

// MARK: - MyCell

class MyCell: UICollectionViewCell {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    private let deleteBadge = UIImageView()
    private let favBadge = UIImageView()

    var imageURL: URL? {
        didSet {
            guard let url = imageURL else { imageView.image = nil; return }
            imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "placeholdertext.fill"))
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 13.5
        imageView.layer.cornerCurve = .continuous
        imageView.tintColor = .systemGray3
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
        ])

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 0.12
        contentView.layer.shadowRadius = 4

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.textColor = UIColor(red: 90/255, green: 97/255, blue: 119/255, alpha: 1)
        titleLabel.font = UIFont.systemFont(ofSize: 11.5, weight: .medium)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.white, .darkGray]))
        deleteBadge.image = UIImage(systemName: "minus.circle.fill", withConfiguration: config)
        deleteBadge.isHidden = true
        contentView.addSubview(deleteBadge)
        deleteBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deleteBadge.centerXAnchor.constraint(equalTo: imageView.leadingAnchor),
            deleteBadge.centerYAnchor.constraint(equalTo: imageView.topAnchor),
            deleteBadge.widthAnchor.constraint(equalToConstant: 22),
            deleteBadge.heightAnchor.constraint(equalToConstant: 22),
        ])

        let favConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white]))
        favBadge.image = UIImage(systemName: "star.circle.fill", withConfiguration: favConfig)
        favBadge.isHidden = true
        contentView.addSubview(favBadge)
        favBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            favBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
            favBadge.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            favBadge.widthAnchor.constraint(equalToConstant: 18),
            favBadge.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    func showDeleteBadge(_ show: Bool) { deleteBadge.isHidden = !show }
    func showFavBadge(_ show: Bool) { favBadge.isHidden = !show }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}

#Preview {
    HomeView(showSearch: .constant(false))
}
