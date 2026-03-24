//
//  AppView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Foundation


struct SubAppView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel

    var item: AppModel
    var body: some View {
        VStack {
            HStack {
                if let iconUrl = URL(string: item.icon ?? "") {
                    WebImage(url: iconUrl) { image in
                        image.resizable()
                    } placeholder: {
                        Rectangle().foregroundColor(.gray)
                    }
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(item.name) (\(item.id))")
                            .font(.system(size: 16))
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    Text(AttributedString("\(item.repo ?? "")"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(AttributedString("\(item.author)"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if let isFav = item.isFav, isFav == true {
                    Image(systemName: "star.fill")
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            let updateIds = boxModel.favApps.map { $0.id }.filter { $0 != item.id }
                            boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
                        }
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            var updateIds = boxModel.favApps.map { $0.id }
                            updateIds.append(item.id)
                            boxModel.updateData(path: "usercfgs.favapps", data: updateIds)
                        }

                }
            }
        }
    }
}


struct CustomDisclosureGroup: View {
    @State private var isExpanded: Bool = false
    var title: String
    var items: [AppModel]
    var icon: String?
    var sysIcon: String?
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Divider()
                    .padding(.vertical, 5)
                ScrollView {
                    ForEach(items) { item in
                        NavigationLink(destination: AppDetailView(app: item)) {
                            SubAppView(item: item)
                        }
                    }
                }
                .frame(maxHeight: 300)
            },
            label: {
                HStack {
                    if let icon {
                        WebImage(url: URL(string: icon)) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle().foregroundColor(.gray)
                        }
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else if let sysIcon {
                        Image(systemName: sysIcon)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .foregroundColor(.red)
                    }
                    
                    Text("\(title)(\(items.count))")
                        .font(Font.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        )
        .padding()
        .foregroundColor(.primary)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct AppView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @State private var isScrolled = false

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(urlString: boxModel.boxData.bgImgUrl)
                AppScrollView(onScroll: { offset in isScrolled = offset > 5 }) {
                    if !boxModel.favApps.isEmpty {
                        CustomDisclosureGroup(title: "收藏应用", items: boxModel.favApps, sysIcon: "star.circle.fill")
                    }
                    if boxModel.boxData.displayAppSubs.count != 0 {
                        ForEach(boxModel.boxData.displayAppSubs) { group in
                            CustomDisclosureGroup(
                                title: group.name,
                                items: group.apps,
                                icon: group.icon
                            )
                        }
                    }
                    if !boxModel.boxData.displaySysApps.isEmpty {
                        CustomDisclosureGroup(title: "系统应用", items: boxModel.boxData.displaySysApps, sysIcon: "gearshape.circle.fill")
                    }
                }
                .refreshable { boxModel.fetchData() }
            }
            .navigationBarTitle("应用列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(isScrolled ? .visible : .hidden, for: .navigationBar)
        }
    }
}

private struct AppScrollView<Content: View>: UIViewRepresentable {
    var onScroll: (CGFloat) -> Void
    @ViewBuilder var content: Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.delegate = context.coordinator
        scrollView.refreshControl = {
            let rc = UIRefreshControl()
            rc.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
            return rc
        }()

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
        context.coordinator.host = host
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.host?.rootView = content
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScroll: onScroll) }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var onScroll: (CGFloat) -> Void
        weak var host: UIHostingController<Content>?

        init(onScroll: @escaping (CGFloat) -> Void) { self.onScroll = onScroll }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll(scrollView.contentOffset.y)
        }

        @objc func handleRefresh(_ rc: UIRefreshControl) {
            rc.endRefreshing()
        }
    }
}

private extension UIView {
    func firstScrollView() -> UIScrollView? {
        if let sv = self as? UIScrollView { return sv }
        for sub in subviews {
            if let sv = sub.firstScrollView() { return sv }
        }
        return nil
    }
}

#Preview {
    AppView()
}
