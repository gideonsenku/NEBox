//
//  MacHomeView.swift
//  RelayMac
//

import SwiftUI

struct MacHomeView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if boxModel.favApps.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(boxModel.favApps) { app in
                            NavigationLink(value: MacRoute.app(id: app.id)) {
                                GlassAppCard(app: app)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("复制 ID") {
                                    PlatformBridge.copyToPasteboard(app.id)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("收藏应用")
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
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
}
