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
    init() {
        // hex color f8f8f8
        UITabBar.appearance().backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.00)
        UITabBar.appearance().barTintColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.00)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(toastManager)
                .environmentObject(boxModel)
                .onAppear {
                    Task {
                        await boxModel.fetchData()
                    }
                }
        }
    }
}
