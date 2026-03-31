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
    @State private var showDisclaimer = false

    private var inputIsEmpty: Bool {
        apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image("AppIcon-Light")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                Text("Relay")
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
                        TextField(ApiManager.defaultAPIURL, text: $apiUrlInput)
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
                    apiUrlInput = ApiManager.defaultAPIURL
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .glassButton(isDisabled: inputIsEmpty)
                .disabled(inputIsEmpty)
            }
            .padding(24)
            .glassCard()
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            Text("请确保代理工具正在运行")
                .font(.system(size: 12))
                .foregroundColor(Color(.tertiaryLabel))

            Spacer().frame(height: 20)

            BoxJSInstallGuideView()
                .padding(.horizontal, 24)

            Spacer()

            Button {
                showDisclaimer = true
            } label: {
                Text("免责声明")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
                    .underline()
            }
            .padding(.bottom, 16)
            .sheet(isPresented: $showDisclaimer) {
                NavigationView {
                    DisclaimerView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完成") { showDisclaimer = false }
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }
                }
            }
        }
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = false
                }
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var boxModel: BoxJsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var apiUrlInput: String = ""
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showVersionSheet = false
    @State private var currentVersion: String = ""
    @State private var selectedTab: Int = 0
    @State private var hideFloatingTabBar: Bool = false

    var body: some View {
        VStack {
            if !apiManager.isApiUrlSet() {
                WelcomeSetupView(
                    apiUrlInput: $apiUrlInput,
                    onConnect: {
                        let trimmed = apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            appLog(.info, category: .app, "[WelcomeSetup] connect tapped with host: \(trimmed)")
                            apiManager.apiUrl = trimmed
                            boxModel.fetchData()
                        } else {
                            appLog(.warning, category: .app, "[WelcomeSetup] connect tapped with empty host")
                        }
                    }
                )
            } else {
                mainContent
                    .overlay(GlobalToastView())
                    .modifier(LegacySearchCoverModifier(isPresented: $showSearch))
                    .onReceive(boxModel.$boxData) { data in
                        guard let ver = data.syscfgs?.version, !ver.isEmpty, currentVersion.isEmpty else { return }
                        currentVersion = ver
                        checkVersion()
                    }
            }
        }
        .sheet(isPresented: $showVersionSheet) {
            neboxNavigationContainer {
                VersionHistoryView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("关闭") { showVersionSheet = false }
                        }
                    }
            }
        }
        .background(Color.gradientBottom.ignoresSafeArea(edges: .bottom))
        .onChange(of: selectedTab) { _ in
            Task {
                await boxModel.flushPendingDataUpdates()
            }
        }
        .onReceive(boxModel.$pendingDeepLinkTab.compactMap { $0 }) { tab in
            selectedTab = tab
            boxModel.pendingDeepLinkTab = nil
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                if apiManager.isApiUrlSet() {
                    boxModel.fetchData()
                }
            case .inactive, .background:
                Task {
                    await boxModel.flushPendingDataUpdates()
                }
            @unknown default:
                break
            }
        }
        .onPreferenceChange(NEBoxHideTabBarPreferenceKey.self) { shouldHide in
            hideFloatingTabBar = shouldHide
        }
    }

    // MARK: - Main Content (iOS version adaptive)

    @ViewBuilder
    private var mainContent: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house", value: 0) {
                    HomeView(onSearch: { selectedTab = 3 })
                }
                Tab("Subs", systemImage: "square.stack", value: 1) {
                    SubcribeView()
                }
                Tab("Profile", systemImage: "person", value: 2) {
                    ProfileView()
                }
                Tab("Search", systemImage: "magnifyingglass", value: 3, role: .search) {
                    SearchTabView(searchText: $searchText)
                }
            }
            .tint(NEBoxTabBarPalette.selected)
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case 0:  HomeView(onSearch: { showSearch = true })
                    case 1:  SubcribeView()
                    case 2:  ProfileView()
                    default: HomeView(onSearch: { showSearch = true })
                    }
                }

                if !hideFloatingTabBar {
                    floatingTabBar
                        .zIndex(10)
                }
            }
        }
    }

    // MARK: - Floating Tab Bar (iOS < 26)

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            Button { selectedTab = 0 } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 0 ? NEBoxTabBarPalette.selected : NEBoxTabBarPalette.unselected)
                    Text("HOME")
                        .font(.system(size: 9, weight: selectedTab == 0 ? .bold : .medium))
                        .foregroundColor(selectedTab == 0 ? NEBoxTabBarPalette.selected : NEBoxTabBarPalette.unselected)
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button { selectedTab = 1 } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "square.stack.fill" : "square.stack")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? NEBoxTabBarPalette.selected : NEBoxTabBarPalette.unselected)
                    Text("SUBS")
                        .font(.system(size: 9, weight: selectedTab == 1 ? .bold : .medium))
                        .foregroundColor(selectedTab == 1 ? NEBoxTabBarPalette.selected : NEBoxTabBarPalette.unselected)
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button { selectedTab = 2 } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 2 ? NEBoxTabBarPalette.selected : NEBoxTabBarPalette.unselected)
                    Text("PROFILE")
                        .font(.system(size: 9, weight: selectedTab == 2 ? .bold : .medium))
                        .foregroundColor(selectedTab == 2 ? NEBoxTabBarPalette.selected : NEBoxTabBarPalette.unselected)
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 50)
        .padding(4)
        .glassTabBar()
        .padding(.horizontal, 21)
        .padding(.bottom, 4)
        .animation(nil, value: selectedTab)
    }

    private func checkVersion() {
        Task {
            do {
                let resp: VersionsResp = try await NetworkProvider.request(.getVersions)
                if let releases = resp.releases, !releases.isEmpty {
                    await MainActor.run {
                        if let latest = releases.first,
                           compareVersion(latest.version, currentVersion) > 0 {
                            showVersionSheet = true
                        }
                    }
                }
            } catch {
                appLog(.warning, category: .app, "Version check failed: \(error)")
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
}

// MARK: - Legacy Search Cover (iOS < 26 only)

private struct LegacySearchCoverModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content.fullScreenCover(isPresented: $isPresented) {
                SearchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
