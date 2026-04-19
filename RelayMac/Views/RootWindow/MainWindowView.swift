//
//  MainWindowView.swift
//  RelayMac
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @StateObject private var chrome = WindowChromeModel()
    @State private var selection: SidebarItem? = .home
    @State private var showOnboarding: Bool = false

    var body: some View {
        ZStack {
            WorkbenchWindowBackground()

            HStack(spacing: 0) {
                SidebarView(
                    selection: $selection,
                    isConnected: apiManager.isApiUrlSet()
                )

                if selection?.usesBareLayout == true {
                    DetailRouter(selection: selection)
                        .environmentObject(chrome)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 32)
                } else {
                    detailCard
                        .padding(.vertical, 12)
                        .padding(.leading, 10)
                        .padding(.trailing, 12)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .frame(minWidth: 900, minHeight: 560)
        .sheet(isPresented: $showOnboarding) {
            MacOnboardingSheet()
                .environmentObject(apiManager)
                .environmentObject(toastManager)
                .environmentObject(boxModel)
                .environmentObject(chrome)
        }
        .onAppear { showOnboarding = !apiManager.isApiUrlSet() }
        .onChange(of: apiManager.isApiUrlSet()) { _, isSet in
            showOnboarding = !isSet
        }
        .overlay(alignment: .bottom) {
            MacToast()
                .environmentObject(toastManager)
                .padding(.bottom, 20)
        }
    }

    private var detailCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )

            DetailRouter(selection: selection)
                .environmentObject(chrome)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, hasChromeBar ? 48 : 20)
                .padding(.bottom, 20)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .overlay(alignment: .topLeading) {
            if let back = chrome.backAction {
                InlineBackButton(action: back)
                    .padding(.top, 10)
                    .padding(.leading, 12)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !chrome.actions.isEmpty {
                windowActionBar
                    .padding(.top, 10)
                    .padding(.trailing, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hasChromeBar: Bool {
        !chrome.actions.isEmpty || chrome.backAction != nil
    }

    private var windowActionBar: some View {
        HStack(spacing: 10) {
            ForEach(chrome.actions) { action in
                chromeActionView(action)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func chromeActionView(_ action: WindowChromeAction) -> some View {
        switch action.kind {
        case let .button(handler):
            Button(action: handler) {
                chromeActionLabel(action)
            }
            .buttonStyle(.plain)
            .disabled(action.isDisabled)
            .help(action.title)
        case let .menu(items):
            Menu {
                ForEach(items) { item in
                    Button(role: item.role, action: item.action) {
                        if let systemImage = item.systemImage {
                            Label(item.title, systemImage: systemImage)
                        } else {
                            Text(item.title)
                        }
                    }
                    .disabled(item.isDisabled)
                }
            } label: {
                chromeActionLabel(action)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(action.isDisabled)
            .help(action.title)
        }
    }

    private func chromeActionLabel(_ action: WindowChromeAction) -> some View {
        Image(systemName: action.systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(action.isPrimary ? Color.white : Color.secondary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(action.isPrimary ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.thinMaterial))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(action.isPrimary ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

// MacOnboardingSheet and MacToast are implemented in their own files under RelayMac/Views/.
