//
//  ContentView.swift
//  BoxJs
//
//  Created by Senku on 7/3/24.
//

import SwiftUI

struct ApiConfigView: View {
    @Binding var apiUrlInput: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("请输入后端 API 地址")
                .font(.headline)
            
            TextField("API 地址", text: $apiUrlInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("保存") {
                // 关闭视图的操作交由 ContentView 来处理
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

struct ContentView: View {
    @EnvironmentObject var apiManager: ApiManager
    @State private var showApiConfigSheet = false
    @State private var apiUrlInput: String = ""

    var body: some View {
        VStack {
            if !apiManager.isApiUrlSet() {
                Text("请配置后端 API 地址")
                    .padding()

                Button(action: {
                    showApiConfigSheet = true
                }) {
                    Text("配置 API 地址")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
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
        .sheet(isPresented: $showApiConfigSheet) {
            ApiConfigView(apiUrlInput: $apiUrlInput)
                .onDisappear {
                    if !apiUrlInput.isEmpty {
                        apiManager.apiUrl = apiUrlInput
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
