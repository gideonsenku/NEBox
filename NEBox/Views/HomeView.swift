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
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: 80, height: 100)
        
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
        context.coordinator.items = items
        context.coordinator.isEditMode = isEditMode
        uiView.reloadData()
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
                guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                    break
                }
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            case .changed:
                collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            case .ended:
                collectionView.endInteractiveMovement()
            default:
                collectionView.cancelInteractiveMovement()
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
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowRadius = 3
        imageView.tintColor = UIColor.gray
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.textColor = .label
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

        // Delete badge
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        deleteBadge.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        deleteBadge.tintColor = .systemRed
        deleteBadge.isHidden = true
        contentView.addSubview(deleteBadge)
        deleteBadge.translatesAutoresizingMaskIntoConstraints = false
        deleteBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -6).isActive = true
        deleteBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6).isActive = true
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
