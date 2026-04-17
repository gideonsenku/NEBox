import SwiftUI
import UIKit
import SDWebImageSwiftUI
import os.log

private let homeLog = Logger(subsystem: "Relay", category: "HomeView")

/// Fallback icon URL derived from env id
private func fallbackIconURL(for envId: String) -> String {
    let key = envId.lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
    return "https://raw.githubusercontent.com/Orz-3/mini/master/Color/\(key).png"
}

/// URL scheme to open the corresponding proxy app
private func appURLScheme(for envId: String) -> String? {
    switch envId.lowercased().replacingOccurrences(of: " ", with: "") {
    case "loon":          return "loon://"
    case "surge":         return "surge://"
    case "shadowrocket":  return "shadowrocket://"
    case "quantumultx", "quanx":   return "quantumult-x://"
    case "stash":         return "stash://"
    default:              return nil
    }
}

/// Icon URL for a SysEnv based on color scheme: icons[0] = dark, icons[1] = light
private func iconURL(for env: SysEnv, isDark: Bool) -> String {
    if let icons = env.icons {
        let index = isDark ? 0 : 1
        if index < icons.count, !icons[index].isEmpty { return icons[index] }
        if let first = icons.first, !first.isEmpty { return first }
    }
    return fallbackIconURL(for: env.id)
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @Environment(\.colorScheme) private var colorScheme
    var onSearch: () -> Void

    @State var items: [AppModel] = []
    @State private var selectedApp: AppModel? = nil
    @State private var isNavigationActive: Bool = false
    @State private var isEditMode: Bool = false

    private var activeEnv: String? { boxModel.boxData.syscfgs?.env }
    private var availableEnvs: [SysEnv] { boxModel.boxData.syscfgs?.envs ?? [] }

    var body: some View {
        neboxNavigationContainer {
            ZStack(alignment: .top) {
                // Gradient background
                LinearGradient(
                    colors: Color.pageGradientColors,
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
                .onDisappear { isEditMode = false }
                .onReceive(boxModel.$favApps) { favApps in
                    items = favApps
                }

            }
            .neboxHiddenNavigationBar()
            .neboxNavigationDestination(isPresented: $isNavigationActive) {
                AppDetailView(app: selectedApp)
            }
        }
        .neboxLiquidGlassTabBarChrome()
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 0) {
            // Left: current tool indicator, tap to open the app
            Button {
                openProxyApp()
            } label: {
                toolAvatarView
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Right: edit / search
            HStack(spacing: 16) {
                if !boxModel.favApps.isEmpty {
                    Button {
                        isEditMode.toggle()
                    } label: {
                        Text(isEditMode ? "完成" : "编辑")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.accent)
                    }
                }
                Button {
                    onSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.accent)
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
                    return iconURL(for: sysEnv, isDark: colorScheme == .dark)
                }
                return fallbackIconURL(for: envId)
            }()
            WebImage(url: URL(string: urlString)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Text(envId.prefix(1))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gradientTop)
            }
        } else {
            Image(systemName: "network")
                .font(.system(size: 18))
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gradientTop)
        }
    }

    // MARK: - Actions

    private func openProxyApp() {
        guard let envId = activeEnv,
              let scheme = appURLScheme(for: envId),
              let url = URL(string: scheme) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary.opacity(0.4))
            Text("还没有收藏应用")
                .foregroundColor(.textSecondary.opacity(0.7))
            Button {
                onSearch()
            } label: {
                Text("搜索并添加")
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accent)
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
    var bottomInset: CGFloat = adaptiveBottomInset()
    var allowsEdit: Bool = true
    var tapOverride: ((AppModel) -> Void)? = nil
    var favAppIds: Set<String> = []
    var contextMenuProvider: ((AppModel) -> UIMenu?)? = nil

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

        // Allow navigation swipe back gesture to work alongside collection view scrolling
        if let panGesture = collectionView.panGestureRecognizer as? UIPanGestureRecognizer {
            context.coordinator.setupEdgeSwipeSupport(for: collectionView, panGesture: panGesture)
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(context.coordinator.handleRefresh(_:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let coord = context.coordinator
        let itemIDs = items.map(\.id)
        let editModeChanged = isEditMode != coord.prevEditMode
        let itemsChanged = itemIDs != coord.prevItemIDs
        let favChanged = favAppIds != coord.prevFavAppIds
        let shouldReload = itemsChanged || favChanged || editModeChanged

        // Only update non-binding properties; @Binding already reflects parent state
        coord.tapOverride = tapOverride
        coord.favAppIds = favAppIds
        coord.contextMenuProvider = contextMenuProvider
        coord.prevEditMode = isEditMode
        coord.prevItemIDs = itemIDs
        coord.prevFavAppIds = favAppIds

        if shouldReload {
            if uiView.refreshControl?.isRefreshing == true {
                // Defer reload until after refresh animation completes to avoid stutter
                coord.needsReloadAfterRefresh = true
            } else {
                uiView.reloadData()
            }
        }
        if editModeChanged {
            coord.applyJiggle(to: uiView, enabled: isEditMode)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, boxModel: boxModel, selectedApp: $selectedApp, isNavigationActive: $isNavigationActive, isEditMode: $isEditMode, allowsEdit: allowsEdit, tapOverride: tapOverride, favAppIds: favAppIds, contextMenuProvider: contextMenuProvider)
    }

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
        @Binding var items: [AppModel]
        var boxModel: BoxJsViewModel
        @Binding var selectedApp: AppModel?
        @Binding var isNavigationActive: Bool
        @Binding var isEditMode: Bool
        var allowsEdit: Bool
        var tapOverride: ((AppModel) -> Void)?
        var favAppIds: Set<String>
        var contextMenuProvider: ((AppModel) -> UIMenu?)?
        var prevEditMode: Bool = false
        var prevItemIDs: [String]
        var prevFavAppIds: Set<String>
        var needsReloadAfterRefresh = false
        weak var collectionView: UICollectionView?
        private weak var navPopGesture: UIGestureRecognizer?

        init(items: Binding<[AppModel]>, boxModel: BoxJsViewModel, selectedApp: Binding<AppModel?>, isNavigationActive: Binding<Bool>, isEditMode: Binding<Bool>, allowsEdit: Bool, tapOverride: ((AppModel) -> Void)?, favAppIds: Set<String>, contextMenuProvider: ((AppModel) -> UIMenu?)?) {
            _items = items
            self.boxModel = boxModel
            _selectedApp = selectedApp
            _isNavigationActive = isNavigationActive
            _isEditMode = isEditMode
            self.allowsEdit = allowsEdit
            self.tapOverride = tapOverride
            self.favAppIds = favAppIds
            self.contextMenuProvider = contextMenuProvider
            self.prevItemIDs = items.wrappedValue.map(\.id)
            self.prevFavAppIds = favAppIds
        }

        /// Configure collection view's pan gesture to allow navigation back swipe from left edge
        func setupEdgeSwipeSupport(for collectionView: UICollectionView, panGesture: UIPanGestureRecognizer) {
            // Find the navigation controller's interactive pop gesture
            var responder: UIResponder? = collectionView
            while let next = responder?.next {
                if let nav = next as? UINavigationController,
                   let popGesture = nav.interactivePopGestureRecognizer {
                    navPopGesture = popGesture
                    // Make collection view's pan gesture require the pop gesture to fail
                    // This means if pop gesture recognizes (from left edge), pan won't interfere
                    panGesture.require(toFail: popGesture)
                    // Enable the pop gesture
                    popGesture.isEnabled = true
                    popGesture.delegate = nil
                    break
                }
                responder = next
            }
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
            cell.app = app
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
                selectedApp = app
                isNavigationActive = true
            }
        }

        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            Task {
                await boxModel.fetchDataAsync()
                await MainActor.run {
                    refreshControl.endRefreshing()
                    if needsReloadAfterRefresh, let cv = collectionView {
                        needsReloadAfterRefresh = false
                        cv.reloadData()
                    }
                }
            }
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

        func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            guard let contextMenuProvider else { return nil }
            let app = items[indexPath.item]
            guard let menu = contextMenuProvider(app) else { return nil }
            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { _ in menu }
        }

        func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            iconPreview(collectionView: collectionView, configuration: configuration)
        }

        func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            iconPreview(collectionView: collectionView, configuration: configuration)
        }

        private func iconPreview(collectionView: UICollectionView, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            guard let indexPath = configuration.identifier as? IndexPath,
                  let cell = collectionView.cellForItem(at: indexPath) as? MyCell else { return nil }
            let params = UIPreviewParameters()
            params.backgroundColor = .clear
            params.visiblePath = UIBezierPath(
                roundedRect: cell.imageView.bounds,
                cornerRadius: cell.imageView.layer.cornerRadius
            )
            return UITargetedPreview(view: cell.imageView, parameters: params)
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

// MARK: - 3D Printing Community

private struct MakerHeroMetric: Identifiable {
    let id = UUID()
    let value: String
    let label: String
}

private struct MakerFeedItem: Identifiable {
    let id = UUID()
    let title: String
    let maker: String
    let category: String
    let summary: String
    let accent: Color
    let symbol: String
    let stats: String
}

private struct MakerEvent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let time: String
    let accent: Color
}

private struct MakerResource: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
}

struct MakerCommunityView: View {
    private let metrics: [MakerHeroMetric] = [
        .init(value: "18.4K", label: "活跃创客"),
        .init(value: "2.1K", label: "本周作品"),
        .init(value: "96%", label: "打印成功率")
    ]

    private let featuredPrints: [MakerFeedItem] = [
        .init(
            title: "模块化桌搭收纳塔",
            maker: "LayerLab",
            category: "功能件",
            summary: "磁吸分层结构，兼容 Bambu / Prusa 常见平台，附带可替换抽屉和线槽。",
            accent: .accentBlue,
            symbol: "shippingbox.fill",
            stats: "1.2K 收藏"
        ),
        .init(
            title: "轻量化 FPV 云台支架",
            maker: "NozzleWorks",
            category: "无人机",
            summary: "针对 TPU 边界厚度重新优化支撑，保留抗震强度，减少 23% 材料消耗。",
            accent: .accentCoral,
            symbol: "airplane.circle.fill",
            stats: "7h 前更新"
        ),
        .init(
            title: "可拼接机械键盘腕托",
            maker: "Print Commune",
            category: "桌面外设",
            summary: "蜂窝底纹与快拆拼接结构结合，支持多尺寸键盘和双色耗材拼色。",
            accent: .accentWarning,
            symbol: "keyboard.fill",
            stats: "842 条讨论"
        )
    ]

    private let events: [MakerEvent] = [
        .init(title: "48 小时快速改件挑战", subtitle: "围绕旧设备升级件做二创，提交 STL + 参数截图。", time: "进行中", accent: .accentBlue),
        .init(title: "上海线下校准工作坊", subtitle: "喷嘴温度塔、流量补偿、耗材含水率判断集中交流。", time: "周六 14:00", accent: .accentCoral),
        .init(title: "树脂后处理经验 AMA", subtitle: "邀请牙科与手办方向作者分享清洗、固化与防脆裂策略。", time: "今晚 20:00", accent: .accentWarning)
    ]

    private let resources: [MakerResource] = [
        .init(title: "打印参数库", detail: "按材料、喷嘴、层高筛选社区验证配置。", symbol: "slider.horizontal.3"),
        .init(title: "失败案例墙", detail: "拉丝、翘边、分层、象脚等问题快速对照。", symbol: "exclamationmark.triangle.fill"),
        .init(title: "同城 MakerSpace", detail: "查找附近设备、课程和共享后处理工位。", symbol: "map.fill")
    ]

    var body: some View {
        neboxNavigationContainer {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color(hex: "#F7FBFF"),
                        Color(hex: "#EAF4FF"),
                        Color.gradientBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection
                        quickActions
                        featuredSection
                        challengeSection
                        resourceSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, adaptiveBottomInset())
                }
            }
            .neboxHiddenNavigationBar()
        }
        .neboxLiquidGlassTabBarChrome()
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("3D 打印社区平台")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Text("发现优秀模型、校准经验与同城创客，让打印不再只停留在 slicer。")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBlue.opacity(0.18), Color.accentCoral.opacity(0.24)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)

                    Image(systemName: "printer.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.accentBlue)
                }
            }

            HStack(spacing: 12) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.value)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text(metric.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .glassCard(cornerRadius: 18)
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            Color(hex: "#F2F8FF").opacity(0.94),
                            Color(hex: "#FFF6EC").opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: .accentBlue.opacity(0.08), radius: 24, y: 12)
        )
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            makerActionCard(
                title: "发布模型",
                subtitle: "上传 STL / 3MF",
                symbol: "square.and.arrow.up.fill",
                accent: .accentBlue
            )
            makerActionCard(
                title: "校准求助",
                subtitle: "带图发帖",
                symbol: "wrench.and.screwdriver.fill",
                accent: .accentCoral
            )
            makerActionCard(
                title: "找同城",
                subtitle: "共享设备",
                symbol: "person.3.fill",
                accent: .accentWarning
            )
        }
    }

    private func makerActionCard(title: String, subtitle: String, symbol: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 38, height: 38)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 20)
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "本周热门作品", subtitle: "结合下载、收藏与讨论热度排序")

            ForEach(featuredPrints) { item in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(item.accent.opacity(0.12))
                                .frame(width: 58, height: 58)
                            Image(systemName: item.symbol)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(item.accent)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(item.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Text(item.category)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(item.accent.opacity(0.12), in: Capsule())
                                    .foregroundColor(item.accent)
                            }

                            Text("by \(item.maker)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Text(item.summary)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Label(item.stats, systemImage: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(item.accent)
                        Spacer()
                        Button("查看详情") {}
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.accent)
                    }
                }
                .padding(18)
                .glassCard(cornerRadius: 24)
            }
        }
    }

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "社区活动", subtitle: "把线上内容和线下交流串起来")

            ForEach(events) { event in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(event.accent)
                            .frame(width: 10, height: 10)
                        Rectangle()
                            .fill(event.accent.opacity(0.22))
                            .frame(width: 2, height: 54)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(event.title)
                                .font(.system(size: 16, weight: .semibold))
                            Spacer(minLength: 8)
                            Text(event.time)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(event.accent)
                        }
                        Text(event.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .glassCard(cornerRadius: 22)
            }
        }
    }

    private var resourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "创作工具箱", subtitle: "从调机到发布，给新手和老手都留入口")

            ForEach(resources) { resource in
                HStack(spacing: 14) {
                    Image(systemName: resource.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentBlue)
                        .frame(width: 42, height: 42)
                        .background(Color.accentBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.title)
                            .font(.system(size: 15, weight: .semibold))
                        Text(resource.detail)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textInactive)
                }
                .padding(16)
                .glassCard(cornerRadius: 20)
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - MyCell

class MyCell: UICollectionViewCell {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    private let deleteBadge = UIImageView()
    private let favBadge = UIImageView()

    /// The app whose icon this cell displays — kept for adaptive icon switching.
    var app: AppModel? {
        didSet { updateIcon() }
    }

    private lazy var fallbackLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor(.textSecondary)
        if let descriptor = UIFont.systemFont(ofSize: 60 * 0.42, weight: .semibold)
            .fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            label.font = .systemFont(ofSize: 60 * 0.42, weight: .semibold)
        }
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
        return label
    }()

    private func updateIcon() {
        guard let app else { imageView.image = nil; hideFallbackLabel(); return }
        let appearance = IconAppearance(rawValue: UserDefaults.standard.string(forKey: IconAppearance.userDefaultsKey) ?? "") ?? .auto
        let isDark = appearance.isDark(systemIsDark: traitCollection.userInterfaceStyle == .dark)
        imageView.backgroundColor = isDark ? UIColor(.bgCard) : .clear
        if let url = app.adaptiveIconURL(isDark: isDark) {
            // Downsample to display size (60pt × @3x = 180px) to avoid decoding
            // full-resolution bitmaps into memory.
            let thumbSize = CGSize(width: 180, height: 180)
            imageView.sd_setImage(with: url, placeholderImage: nil, options: [], context: [.imageThumbnailPixelSize: thumbSize], progress: nil) { [weak self] image, _, _, _ in
                guard let self else { return }
                if image == nil {
                    self.showFallbackLabel(for: app.name)
                } else {
                    self.hideFallbackLabel()
                }
            }
        } else {
            showFallbackLabel(for: app.name)
        }
    }

    private func showFallbackLabel(for name: String) {
        imageView.image = nil
        imageView.backgroundColor = UIColor(.bgMuted)
        fallbackLabel.text = name.first.map(String.init)
        fallbackLabel.isHidden = false
    }

    private func hideFallbackLabel() {
        fallbackLabel.isHidden = true
    }

    private var iconAppearanceObserver: NSObjectProtocol?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateIcon()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60 * 0.2237 // iOS home-screen icon ratio
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
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textColor = UIColor(.textSecondary)
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

        iconAppearanceObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateIcon()
        }
    }

    deinit {
        if let observer = iconAppearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func showDeleteBadge(_ show: Bool) { deleteBadge.isHidden = !show }
    func showFavBadge(_ show: Bool) { favBadge.isHidden = !show }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}

#Preview {
    HomeView(onSearch: {})
}
