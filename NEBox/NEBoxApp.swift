//
//  NEBoxApp.swift
//  NEBoxApp
//
//  Created by Senku on 7/3/24.
//

import SwiftUI
import UIKit

@main
struct NEBoxApp: App {
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

        LogManager.shared.log(.info, category: .app, "App launched")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiManager)
                .environmentObject(toastManager)
                .environmentObject(boxModel)
                .onAppear {
                    boxModel.toastManager = toastManager
                    if apiManager.isApiUrlSet() {
                        DispatchQueue.main.async {
                            boxModel.fetchData()
                        }
                    }
                }
        }
    }
}
