//
//  RelayApp.swift
//  Relay
//
//  Created by Senku on 7/3/24.
//

import SDWebImage
import SwiftUI
import UIKit

@main
struct RelayApp: App {
    @StateObject private var toastManager = ToastManager()
    @StateObject var boxModel = BoxJsViewModel()
    @StateObject private var apiManager = ApiManager.shared
    init() {
        if #unavailable(iOS 26.0) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithTransparentBackground()
            tabBarAppearance.backgroundColor = .clear
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UITabBar.appearance().isTranslucent = true
        }

        if #available(iOS 26.0, *) {
            // Unselected tab icons/labels (selected uses SwiftUI `.tint` on `TabView`).
            UITabBar.appearance().unselectedItemTintColor = NEBoxTabBarPalette.unselectedUIKit
            UITabBar.appearance().tintColor = NEBoxTabBarPalette.selectedUIKit
        }

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        navBarAppearance.shadowColor = .clear
        navBarAppearance.backgroundEffect = nil
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        // Limit SDWebImage memory cache to ~50 MB to avoid memory spikes when
        // many subscription/app icons are loaded at once.
        let imageCache = SDImageCache.shared
        imageCache.config.maxMemoryCost = 50 * 1024 * 1024

        LogManager.shared.log(.info, category: .app, "App launched")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiManager)
                .environmentObject(toastManager)
                .environmentObject(boxModel)
                .overlay {
                    GlobalLoadingOverlay(toastManager: toastManager)
                }
                .animation(.easeInOut(duration: 0.2), value: toastManager.loadingMessage != nil)
                .onAppear {
                    boxModel.toastManager = toastManager
                    if apiManager.isApiUrlSet() {
                        DispatchQueue.main.async {
                            boxModel.fetchData()
                        }
                    }
                }
                .onOpenURL { url in
                    handleIncomingFile(url: url)
                }
        }
    }

    private func handleIncomingFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let jsonString = String(data: data, encoding: .utf8),
              !jsonString.isEmpty else {
            toastManager.showToast(message: "文件读取失败")
            return
        }

        guard apiManager.isApiUrlSet() else {
            toastManager.showToast(message: "请先配置 API 地址")
            return
        }

        toastManager.showLoading(message: "正在读取文件…")
        Task {
            toastManager.showLoading(message: "正在导入备份…")
            await boxModel.impGlobalBak(bakData: jsonString)
            toastManager.showLoading(message: "导入成功")
            try? await Task.sleep(nanoseconds: 800_000_000)
            toastManager.hideLoading()
        }
    }
}
