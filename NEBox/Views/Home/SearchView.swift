//
//  SearchView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct SearchView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var filteredApps: [AppModel] {
        if searchText.isEmpty {
            return boxModel.boxData.apps
        }
        let query = searchText.lowercased()
        return boxModel.boxData.apps.filter {
            $0.id.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索应用", text: $searchText)
                            .focused($isSearchFocused)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Results list
                List {
                    ForEach(filteredApps) { app in
                        NavigationLink(destination: AppDetailView(app: app)) {
                            HStack(spacing: 12) {
                                if let iconUrl = URL(string: app.icon ?? "") {
                                    WebImage(url: iconUrl)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 40, height: 40)
                                }

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
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)
            .onAppear {
                isSearchFocused = true
            }
        }
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
