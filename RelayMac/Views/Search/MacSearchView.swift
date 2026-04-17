//
//  MacSearchView.swift
//  RelayMac
//

import SwiftUI

struct MacSearchView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var query: String = ""

    private var filtered: [AppModel] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return boxModel.boxData.apps.filter { app in
            app.name.lowercased().contains(trimmed)
            || app.id.lowercased().contains(trimmed)
            || app.author.lowercased().contains(trimmed)
        }
    }

    private var favorites: [String] {
        boxModel.boxData.usercfgs?.favapps ?? []
    }

    var body: some View {
        NavigationStack {
            Group {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    emptyIdleState
                } else if filtered.isEmpty {
                    emptyResultsState
                } else {
                    List {
                        ForEach(filtered) { app in
                            NavigationLink(value: MacRoute.app(id: app.id)) {
                                SearchResultRow(
                                    app: app,
                                    isFavorite: favorites.contains(app.id),
                                    onToggleFavorite: { toggleFavorite(app) }
                                )
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .searchable(text: $query, placement: .toolbar, prompt: "按名称、ID 或作者搜索")
            .navigationTitle("搜索")
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
        }
    }

    private var emptyIdleState: some View {
        ContentUnavailableView(
            "搜索应用",
            systemImage: "magnifyingglass",
            description: Text("输入名称、ID 或作者关键词")
        )
    }

    private var emptyResultsState: some View {
        ContentUnavailableView.search(text: query)
    }

    // MARK: - Actions

    private func toggleFavorite(_ app: AppModel) {
        var favs = favorites
        if favs.contains(app.id) {
            favs.removeAll { $0 == app.id }
            toastManager.showToast(message: "已取消收藏")
        } else {
            favs.append(app.id)
            toastManager.showToast(message: "已添加收藏")
        }
        boxModel.updateData(path: "usercfgs.favapps", data: favs)
        Task { await boxModel.flushPendingDataUpdates() }
    }
}
