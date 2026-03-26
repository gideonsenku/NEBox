//
//  NEBoxApp.swift
//  NEBoxApp
//
//  Created by Senku on 7/3/24.
//

import SwiftUI

@main
struct NEBoxApp: App {
    @StateObject private var toastManager = ToastManager()
    @StateObject var boxModel = BoxJsViewModel()
    @StateObject private var apiManager = ApiManager.shared
    init() {
        // Make all container backgrounds transparent so the global background shows through
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        navBarAppearance.shadowColor = .clear
        navBarAppearance.backgroundEffect = nil
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

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
