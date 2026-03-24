//
//  ContentView.swift
//  BoxJs
//
//  Created by Senku on 7/3/24.
//

import SwiftUI

struct ApiConfigView: View {
    @Binding var apiUrlInput: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("请输入后端 API 地址")
                    .font(.headline)
                TextField("http://boxjs.com", text: $apiUrlInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                Text("BoxJs 默认地址为 http://boxjs.com\n请确保代理工具正在运行")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("配置 API")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave() }
                        .disabled(apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var boxModel: BoxJsViewModel
    @State private var showApiConfigSheet = false
    @State private var apiUrlInput: String = ""
    @State private var showSearch = false
    @State private var showVersionSheet = false
    @State private var versions: [VersionInfo] = []
    @State private var currentVersion: String = ""

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
                        HomeView(showSearch: $showSearch)
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
                        ProfileView()
                            .tabItem {
                                Label("我的", systemImage: "person.crop.circle")
                            }
                    }
                .overlay(GlobalToastView())
                .fullScreenCover(isPresented: $showSearch) {
                    SearchView()
                }
                .onReceive(boxModel.$boxData) { data in
                    if let ver = data.syscfgs?.version, !ver.isEmpty, currentVersion.isEmpty {
                        currentVersion = ver
                        checkVersion()
                    }
                }
            }
        }
        .sheet(isPresented: $showApiConfigSheet) {
            ApiConfigView(
                apiUrlInput: $apiUrlInput,
                onSave: {
                    let trimmed = apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        apiManager.apiUrl = trimmed
                        boxModel.fetchData()
                    }
                    showApiConfigSheet = false
                },
                onCancel: {
                    apiUrlInput = ""
                    showApiConfigSheet = false
                }
            )
        }
        .sheet(isPresented: $showVersionSheet) {
            versionSheet
        }
    }

    private func checkVersion() {
        Task {
            do {
                let resp = try await ApiRequest.getVersions()
                if let releases = resp.releases, !releases.isEmpty {
                    await MainActor.run {
                        versions = releases
                        if let latest = releases.first,
                           compareVersion(latest.version, currentVersion) > 0 {
                            showVersionSheet = true
                        }
                    }
                }
            } catch {
                print("Version check failed: \(error)")
            }
        }
    }

    private func compareVersion(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let count = max(parts1.count, parts2.count)
        for i in 0..<count {
            let a = i < parts1.count ? parts1[i] : 0
            let b = i < parts2.count ? parts2[i] : 0
            if a != b { return a - b }
        }
        return 0
    }

    private var versionSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(versions) { ver in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("v\(ver.version)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(ver.version == currentVersion ? .accentColor : .primary)
                            ForEach(ver.notes, id: \.name) { note in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.name)
                                        .font(.system(size: 14, weight: .semibold))
                                    ForEach(note.descs, id: \.self) { desc in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("\u{2022}")
                                                .font(.system(size: 12))
                                            Text(desc)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.leading, 12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("版本更新")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { showVersionSheet = false }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
