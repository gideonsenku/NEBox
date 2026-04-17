//
//  MacSubscribeDetailView.swift
//  RelayMac
//

import SwiftUI

struct MacSubscribeDetailView: View {
    let sub: AppSubCache

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 18)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Divider()
                grid
            }
            .padding(20)
        }
        .navigationTitle(sub.name)
        .navigationSubtitle("@\(sub.author)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("共 \(sub.apps.count) 个应用")
                .font(.callout).foregroundStyle(.secondary)
            if !sub.repo.isEmpty {
                Text(sub.repo)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private var grid: some View {
        if sub.apps.isEmpty {
            ContentUnavailableView(
                "订阅未包含应用",
                systemImage: "app.dashed",
                description: Text("订阅源缓存为空或尚未加载")
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        } else {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(sub.apps) { app in
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
        }
    }
}
