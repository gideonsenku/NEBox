import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct BackgroundView: View {
    let urlString: String?

    private var normalizedUrl: URL? {
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }
        if let direct = URL(string: raw) {
            return direct
        }
        let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        if let encoded, let url = URL(string: encoded) {
            return url
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            if let url = normalizedUrl {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .id(url.absoluteString)
            } else {
                Color(.systemGroupedBackground)
            }
        }
        .ignoresSafeArea()
    }
}

struct HomeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @Binding var showSearch: Bool
    @State var items: [AppModel] = []
    @State var searchText: String = ""
    @State private var selectedApp: AppModel? = nil
    @State private var isNavigationActive: Bool = false
    @State private var isEditMode: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(urlString: boxModel.boxData.bgImgUrl)

                if !boxModel.isDataLoaded {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if !boxModel.favApps.isEmpty {
                    CollectionViewWrapper(items: $items, boxModel: boxModel, selectedApp: $selectedApp, isNavigationActive: $isNavigationActive, isEditMode: $isEditMode)
                        .ignoresSafeArea()
                        .onReceive(boxModel.$favApps) { newVal in
                            items = newVal
                        }
                } else {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("还没有收藏应用")
                            .foregroundColor(.white.opacity(0.8))
                        Button {
                            showSearch = true
                        } label: {
                            Text("搜索并添加")
                                .font(.system(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                }

                NavigationLink(
                    destination: AppDetailView(app: selectedApp),
                    isActive: $isNavigationActive,
                    label: { EmptyView() }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !boxModel.favApps.isEmpty {
                        Button {
                            isEditMode.toggle()
                        } label: {
                            Text(isEditMode ? "完成" : "编辑")
                                .font(.system(size: 15))
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
    }
}


struct CollectionViewWrapper: UIViewRepresentable {
    @Binding var items: [AppModel]
    var boxModel: BoxJsViewModel
    @Binding var selectedApp: AppModel?
    @Binding var isNavigationActive: Bool
    @Binding var isEditMode: Bool
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 8
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.register(MyCell.self, forCellWithReuseIdentifier: "Cell")
        
        context.coordinator.collectionView = collectionView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(context.coordinator.handleRefresh(_:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)

        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let wasEditMode = context.coordinator.isEditMode
        context.coordinator.items = items
        context.coordinator.isEditMode = isEditMode
        uiView.reloadData()

        // Apply or remove jiggle when edit mode changes
        if isEditMode != wasEditMode {
            // Wait for reloadData to finish so cells exist
            DispatchQueue.main.async {
                context.coordinator.applyJiggle(to: uiView, enabled: isEditMode)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, boxModel: boxModel, selectedApp: $selectedApp, isNavigationActive: $isNavigationActive, isEditMode: $isEditMode)
    }
    
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        @Binding var items: [AppModel]
        var boxModel: BoxJsViewModel
        @Binding var selectedApp: AppModel?
        @Binding var isNavigationActive: Bool
        @Binding var isEditMode: Bool
        weak var collectionView: UICollectionView?

        init(items: Binding<[AppModel]>, boxModel: BoxJsViewModel, selectedApp: Binding<AppModel?>, isNavigationActive: Binding<Bool>, isEditMode: Binding<Bool>) {
            _items = items
            self.boxModel = boxModel
            _selectedApp = selectedApp
            _isNavigationActive = isNavigationActive
            _isEditMode = isEditMode
        }
        
        func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
            return items.count
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let columns: CGFloat = 4
            let totalInset: CGFloat = 32  // 16 + 16
            let width = floor((collectionView.bounds.width - totalInset) / columns)
            return CGSize(width: width, height: 90)
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCell
            let appModel = items[indexPath.item]
            cell.titleLabel.text = appModel.name
            if let imageURLString = appModel.icon, let imageURL = URL(string: imageURLString) {
                cell.imageURL = imageURL
            } else {
                cell.imageView.image = UIImage(systemName: "placeholdertext.fill")
            }
            cell.showDeleteBadge(isEditMode)
            if isEditMode {
                startJiggleAnimation(for: cell)
            } else {
                cell.layer.removeAnimation(forKey: "jiggle")
                cell.transform = .identity
            }
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let appModel = items[indexPath.item]
            if isEditMode {
                // Remove from favorites
                let updateIds = items.map { $0.id }.filter { $0 != appModel.id }
                boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
            } else {
                selectedApp = appModel
                isNavigationActive = true
            }
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            boxModel.fetchData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                refreshControl.endRefreshing()
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let collectionView = collectionView else { return }

            switch gesture.state {
            case .began:
                // If not in edit mode, enter it first
                if !isEditMode {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    isEditMode = true
                    applyJiggle(to: collectionView, enabled: true)
                    updateDeleteBadges(in: collectionView, show: true)
                }
                // Also start drag-to-reorder
                if let indexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) {
                    collectionView.beginInteractiveMovementForItem(at: indexPath)
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
                if enabled {
                    startJiggleAnimation(for: cell)
                } else {
                    cell.layer.removeAnimation(forKey: "jiggle")
                    cell.transform = .identity
                }
            }
        }

        func startJiggleAnimation(for cell: UICollectionViewCell) {
            let angle: CGFloat = .pi / 90  // ~2 degrees
            let randomOffset = Double.random(in: 0...0.08)
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.values = [-angle, angle, -angle]
            animation.keyTimes = [0, 0.5, 1.0]
            animation.duration = 0.25 + randomOffset
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = false
            cell.layer.add(animation, forKey: "jiggle")
        }

        func updateDeleteBadges(in collectionView: UICollectionView, show: Bool) {
            for cell in collectionView.visibleCells {
                if let myCell = cell as? MyCell {
                    myCell.showDeleteBadge(show)
                }
            }
        }
        
        func collectionView(_: UICollectionView, canMoveItemAt _: IndexPath) -> Bool {
            return true
        }
        
        func collectionView(_: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            let movedItem = items.remove(at: sourceIndexPath.item)
            items.insert(movedItem, at: destinationIndexPath.item)
            let updateIds = items.map { $0.id }
            boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
        }
    }
}

class MyCell: UICollectionViewCell {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    private let deleteBadge = UIImageView()

    var imageURL: URL? {
        didSet {
            guard let url = imageURL else {
                imageView.image = nil
                return
            }
            imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "placeholdertext.fill"))
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Icon image — 60pt, iOS 规范圆角比例
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

        // Icon shadow — 放在 imageView 外层容器上才能穿透 clipsToBounds
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowRadius = 4

        // Label — 白字 + 阴影，贴合壁纸背景
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 11.5, weight: .medium)
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        titleLabel.layer.shadowOpacity = 0.6
        titleLabel.layer.shadowRadius = 1.5
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])

        // Delete badge — iOS style: dark gray circle with white minus
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
    }

    func showDeleteBadge(_ show: Bool) {
        deleteBadge.isHidden = !show
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    HomeView(showSearch: .constant(false))
}
