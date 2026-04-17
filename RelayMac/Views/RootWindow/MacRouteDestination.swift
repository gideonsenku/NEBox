//
//  MacRouteDestination.swift
//  RelayMac
//

import SwiftUI

/// Resolves a `MacRoute` to its destination view using the shared BoxJsViewModel.
/// Shared by `MacHomeView` / `MacSubscribeListView` / `MacBackupView`'s
/// `navigationDestination`.
struct MacRouteDestination: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    let route: MacRoute

    var body: some View {
        switch route {
        case .app(let id):
            if let app = boxModel.boxData.apps.first(where: { $0.id == id }) {
                MacAppDetailView(app: app)
            } else {
                ContentUnavailableView(
                    "应用不存在",
                    systemImage: "exclamationmark.triangle",
                    description: Text("id: \(id)")
                )
            }

        case .subscription(let url):
            if let cache = boxModel.boxData.appSubCaches[url] {
                MacSubscribeDetailView(sub: cache)
            } else {
                ContentUnavailableView(
                    "订阅源不存在或未缓存",
                    systemImage: "exclamationmark.triangle",
                    description: Text(url).font(.caption).monospaced()
                )
            }

        case .backup(let id):
            MacBackupDetailView(bakId: id)
        }
    }
}
