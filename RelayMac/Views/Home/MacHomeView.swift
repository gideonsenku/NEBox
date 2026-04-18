//
//  MacHomeView.swift
//  RelayMac
//

import SwiftUI
import SDWebImageSwiftUI

struct MacHomeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var chrome: WindowChromeModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var favoriteItems: [AppModel] = []
    @State private var isEditingFavorites: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if favoriteItems.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    if isEditingFavorites {
                        editingList
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(favoriteItems) { app in
                                    NavigationLink(value: MacRoute.app(id: app.id)) {
                                        GlassAppCard(app: app)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("复制 ID") {
                                            PlatformBridge.copyToPasteboard(app.id)
                                        }
                                        Button("取消收藏", role: .destructive) {
                                            removeFavorite(app)
                                        }
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("收藏应用")
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
            .onAppear {
                favoriteItems = boxModel.favApps
                updateChrome()
            }
            .onReceive(boxModel.$favApps) { favApps in
                guard !isEditingFavorites else { return }
                favoriteItems = favApps
                updateChrome()
            }
            .onChange(of: isEditingFavorites) { _, _ in updateChrome() }
            .onDisappear { chrome.clear() }
        }
    }

    private var editingList: some View {
        List {
            ForEach(favoriteItems) { app in
                editRow(for: app)
                    .contextMenu {
                        Button("复制 ID") {
                            PlatformBridge.copyToPasteboard(app.id)
                        }
                        Button("取消收藏", role: .destructive) {
                            removeFavorite(app)
                        }
                    }
            }
            .onMove(perform: moveFavorites)
            .onDelete(perform: deleteFavorites)
        }
        .listStyle(.inset)
    }

    private func editRow(for app: AppModel) -> some View {
        HStack(spacing: 12) {
            favoriteRowIcon(for: app)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                Text(app.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func favoriteRowIcon(for app: AppModel) -> some View {
        if let url = app.icons.first.flatMap(URL.init(string:)) {
            WebImage(url: url)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Image(systemName: "app")
                .frame(width: 32, height: 32)
                .foregroundStyle(.tertiary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("暂无收藏应用")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(boxModel.boxData.apps.isEmpty
                 ? "BoxJS 数据尚未加载，尝试点击工具栏的「刷新」"
                 : "在订阅源里长按应用并添加到收藏")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func moveFavorites(from source: IndexSet, to destination: Int) {
        favoriteItems.move(fromOffsets: source, toOffset: destination)
        persistFavorites(message: "收藏顺序已更新")
    }

    private func deleteFavorites(at offsets: IndexSet) {
        favoriteItems.remove(atOffsets: offsets)
        persistFavorites(message: "已移除收藏")
    }

    private func removeFavorite(_ app: AppModel) {
        favoriteItems.removeAll { $0.id == app.id }
        persistFavorites(message: "已移除收藏")
    }

    private func persistFavorites(message: String) {
        let ids = favoriteItems.map(\.id)
        boxModel.updateData(path: "usercfgs.favapps", data: ids)
        toastManager.showToast(message: message)
        Task { await boxModel.flushPendingDataUpdates() }
    }

    private func updateChrome() {
        guard !favoriteItems.isEmpty else {
            chrome.clear()
            return
        }
        chrome.setActions([
            WindowChromeAction(
                title: isEditingFavorites ? "完成" : "编辑",
                systemImage: isEditingFavorites ? "checkmark" : "slider.horizontal.3",
                kind: .button(action: { isEditingFavorites.toggle() })
            )
        ])
    }
}
