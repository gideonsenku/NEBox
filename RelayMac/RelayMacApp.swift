//
//  RelayMacApp.swift
//  RelayMac
//

import SDWebImage
import SwiftUI

@main
struct RelayMacApp: App {
    @StateObject private var apiManager = ApiManager.shared
    @StateObject private var boxModel = BoxJsViewModel()
    @StateObject private var toastManager = ToastManager()

    init() {
        let imageCache = SDImageCache.shared
        imageCache.config.maxMemoryCost = 50 * 1024 * 1024
        LogManager.shared.log(.info, category: .app, "RelayMac launched")
    }

    var body: some Scene {
        WindowGroup("Relay") {
            MainWindowView()
                .environmentObject(apiManager)
                .environmentObject(boxModel)
                .environmentObject(toastManager)
                .onAppear {
                    boxModel.toastManager = toastManager
                    if apiManager.isApiUrlSet() {
                        boxModel.fetchData()
                    }
                }
                .onOpenURL(perform: handleURL)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            RelayMenuCommands(boxModel: boxModel, apiManager: apiManager)
        }

        Settings {
            MacPreferencesView()
                .environmentObject(apiManager)
                .environmentObject(boxModel)
                .environmentObject(toastManager)
                .frame(minWidth: 560, minHeight: 400)
        }
    }

    private func handleURL(_ url: URL) {
        LogManager.shared.log(.info, category: .app, "onOpenURL: \(url.absoluteString)")
        if url.scheme == "relay" {
            handleDeepLink(url: url)
        } else {
            handleIncomingFile(url: url)
        }
    }

    private func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }

        switch host {
        case "import":
            guard let subURL = components.queryItems?.first(where: { $0.name == "url" })?.value,
                  !subURL.isEmpty else {
                toastManager.showToast(message: "缺少订阅地址")
                return
            }
            guard apiManager.isApiUrlSet() else {
                toastManager.showToast(message: "请先配置 API 地址")
                return
            }
            toastManager.showLoading(message: "正在添加订阅…")
            Task { @MainActor in
                await boxModel.addAppSub(url: subURL)
                toastManager.hideLoading()
            }
        default:
            break
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

        toastManager.showLoading(message: "正在导入备份…")
        Task { @MainActor in
            await boxModel.impGlobalBak(bakData: jsonString)
            // Let the ViewModel's own toast communicate success/failure.
            toastManager.hideLoading()
        }
    }
}
