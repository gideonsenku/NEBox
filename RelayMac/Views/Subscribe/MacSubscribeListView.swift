//
//  MacSubscribeListView.swift
//  RelayMac
//

import SDWebImageSwiftUI
import SwiftUI

struct MacSubscribeListView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel

    var body: some View {
        NavigationStack {
            List {
                if boxModel.cachedAppSubSummaries.isEmpty {
                    ContentUnavailableView(
                        "暂无订阅源",
                        systemImage: "rectangle.stack",
                        description: Text("在 iOS 端或 API 服务器上添加订阅后会显示在这里")
                    )
                } else {
                    ForEach(boxModel.cachedAppSubSummaries) { sub in
                        if let url = sub.url, !url.isEmpty {
                            NavigationLink(value: MacRoute.subscription(url: url)) {
                                SubscribeRow(sub: sub)
                            }
                        } else {
                            SubscribeRow(sub: sub)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("订阅源")
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
        }
    }
}

private struct SubscribeRow: View {
    let sub: AppSubSummary

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name).font(.body).lineLimit(1)
                Text("\(sub.appCount) 应用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var icon: some View {
        if let url = URL(string: sub.icon), !sub.icon.isEmpty {
            WebImage(url: url).resizable().scaledToFit()
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
        }
    }
}
