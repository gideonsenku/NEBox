import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct BackgroundView: View {
    let imageUrl: URL

    var body: some View {
        GeometryReader { geometry in
            WebImage(url: imageUrl)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct HomeView: View {
    @StateObject var boxModel = BoxJsViewModel()
    @State var items: [AppModel] = []
    @State var searchText: String = ""

    var body: some View {
        ZStack {
            if let url = URL(string: boxModel.boxData.bgImgUrl) {
                BackgroundView(imageUrl: url)
            }
            VStack {
//                SearchBar(text: $searchText)
                if !boxModel.favApps.isEmpty {
                    CollectionViewWrapper(items: $items, boxModel: boxModel)
                        .ignoresSafeArea()
                        .onReceive(boxModel.$favApps) { newVal in
                            items = newVal
                        }
                } else {
                    ProgressView()
                        .onAppear {
                            DispatchQueue.main.async {
                                boxModel.fetchData()
                            }
                        }
                }
            }
        }
    }
}

struct CollectionViewWrapper: UIViewRepresentable {
    @Binding var items: [AppModel]
    var boxModel: BoxJsViewModel

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

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.items = items
        uiView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, boxModel: boxModel)
    }

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        @Binding var items: [AppModel]
        var boxModel: BoxJsViewModel
        weak var collectionView: UICollectionView?

        init(items: Binding<[AppModel]>, boxModel: BoxJsViewModel) {
            _items = items
            self.boxModel = boxModel
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
            return cell
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
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    HomeView()
}
