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
    @State private var importingMessage: String? = nil
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
                    if let message = importingMessage {
                        VStack(spacing: 14) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .frame(width: 120, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: importingMessage != nil)
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

        importingMessage = "正在读取文件…"
        Task {
            importingMessage = "正在导入备份…"
            await boxModel.impGlobalBak(bakData: jsonString)
            importingMessage = "导入成功"
            try? await Task.sleep(nanoseconds: 800_000_000)
            importingMessage = nil
        }
    }
}
