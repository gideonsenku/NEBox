//
//  SearchTabView.swift
//  Relay
//
//  Created by Senku on 2026.
//

import SwiftUI
import SDWebImageSwiftUI

@available(iOS 26.0, *)
struct SearchTabView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @Binding var searchText: String

    private var filteredApps: [AppModel] {
        if searchText.isEmpty {
            return boxModel.cachedApps
        }
        let query = searchText.lowercased()
        return boxModel.cachedApps.filter {
            $0.id.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredApps) { app in
                NavigationLink(destination: AppDetailView(app: app)) {
                    HStack(spacing: 12) {
                        AppIconView(app: app, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(app.name) (\(app.id))")
                                .font(.system(size: 14))
                                .lineLimit(1)
                            if let repo = app.repo {
                                Text(repo)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Text(app.author)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            toggleFav(app)
                        } label: {
                            Image(systemName: app.isFav == true ? "star.fill" : "star")
                                .foregroundColor(app.isFav == true ? .accentColor : .gray)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
        }
        .searchable(text: $searchText, prompt: "搜索应用")
    }

    private func toggleFav(_ app: AppModel) {
        var favIds = boxModel.boxData.usercfgs?.favapps ?? []
        if let idx = favIds.firstIndex(of: app.id) {
            favIds.remove(at: idx)
        } else {
            favIds.append(app.id)
        }
        boxModel.updateData(path: "usercfgs.favapps", data: favIds)
    }
}
