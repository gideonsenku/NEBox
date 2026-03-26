//
//  ContentView.swift
//  BoxJs
//
//  Created by Senku on 7/3/24.
//

import SwiftUI

struct WelcomeSetupView: View {
    @Binding var apiUrlInput: String
    var onConnect: () -> Void

    @FocusState private var isFocused: Bool

    private var inputIsEmpty: Bool {
        apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image("BoxJs")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                Text("NEBox")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("BoxJs 客户端")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 48)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("后端地址")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                        TextField("http://boxjs.com", text: $apiUrlInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 15))
                            .focused($isFocused)
                        if !apiUrlInput.isEmpty {
                            Button {
                                apiUrlInput = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(10)
                }

                Button {
                    apiUrlInput = "http://boxjs.com"
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 11))
                        Text("使用默认地址")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.accentColor)
                }
                .opacity(apiUrlInput.isEmpty ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: apiUrlInput.isEmpty)

                Button(action: onConnect) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                        Text("连接")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(inputIsEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                    )
                }
                .disabled(inputIsEmpty)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            Text("请确保代理工具正在运行")
                .font(.system(size: 12))
                .foregroundColor(Color(.tertiaryLabel))

            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct ContentView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var boxModel: BoxJsViewModel
    @State private var apiUrlInput: String = ""
    @State private var showSearch = false
    @State private var showVersionSheet = false
    @State private var versions: [VersionInfo] = []
    @State private var currentVersion: String = ""
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack {
            if !apiManager.isApiUrlSet() {
                WelcomeSetupView(
                    apiUrlInput: $apiUrlInput,
                    onConnect: {
                        let trimmed = apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            apiManager.apiUrl = trimmed
                            boxModel.fetchData()
                        }
                    }
                )
            } else {
                ZStack(alignment: .bottom) {
                    HomeView(showSearch: $showSearch)
                        .opacity(selectedTab == 0 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 0)
                        .zIndex(selectedTab == 0 ? 1 : 0)

                    SubcribeView()
                        .opacity(selectedTab == 1 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 1)
                        .zIndex(selectedTab == 1 ? 1 : 0)

                    ProfileView()
                        .opacity(selectedTab == 2 ? 1 : 0)
                        .allowsHitTesting(selectedTab == 2)
                        .zIndex(selectedTab == 2 ? 1 : 0)

                    floatingTabBar
                        .zIndex(10)
                }
                .overlay(GlobalToastView())
                .fullScreenCover(isPresented: $showSearch) {
                    SearchView()
                }
                .onReceive(boxModel.$boxData) { data in
                    guard let ver = data.syscfgs?.version, !ver.isEmpty, currentVersion.isEmpty else { return }
                    DispatchQueue.main.async {
                        currentVersion = ver
                        checkVersion()
                    }
                }
            }
        }
        .sheet(isPresented: $showVersionSheet) {
            versionSheet
        }
        // Fill bottom safe area with gradient end color
        .background(Color(hex: "#F5F0F8").ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Floating Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            Button { selectedTab = 0 } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 0 ? Color(hex: "#002FA7") : Color(hex: "#A0A8BD"))
                    Text("HOME")
                        .font(.system(size: 9, weight: selectedTab == 0 ? .bold : .medium))
                        .foregroundColor(selectedTab == 0 ? Color(hex: "#002FA7") : Color(hex: "#A0A8BD"))
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
            }

            Button { selectedTab = 1 } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "square.stack.fill" : "square.stack")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? Color(hex: "#002FA7") : Color(hex: "#A0A8BD"))
                    Text("SUBS")
                        .font(.system(size: 9, weight: selectedTab == 1 ? .bold : .medium))
                        .foregroundColor(selectedTab == 1 ? Color(hex: "#002FA7") : Color(hex: "#A0A8BD"))
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
            }

            Button { selectedTab = 2 } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 2 ? Color(hex: "#002FA7") : Color(hex: "#A0A8BD"))
                    Text("PROFILE")
                        .font(.system(size: 9, weight: selectedTab == 2 ? .bold : .medium))
                        .foregroundColor(selectedTab == 2 ? Color(hex: "#002FA7") : Color(hex: "#A0A8BD"))
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 50)
        .padding(4)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
        .padding(.horizontal, 21)
        .padding(.bottom, 4)
    }

    private func checkVersion() {
        Task {
            do {
                let resp: VersionsResp = try await NetworkProvider.request(.getVersions)
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
