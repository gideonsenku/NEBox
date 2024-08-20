//
//  ContentView.swift
//  BoxJs
//
//  Created by Senku on 7/3/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("主页", systemImage: "house")
                }
            AppView()
                .tabItem {
                    Label("应用", systemImage: "app")
                }
            SubcribeView()
                .tabItem {
                    Label("订阅", systemImage: "cloud")
                }
            SettingView()
                .tabItem {
                    Label("设置", systemImage: "paintpalette")
                }
        }
        .overlay(GlobalToastView())
    }
}

#Preview {
    ContentView()
}
