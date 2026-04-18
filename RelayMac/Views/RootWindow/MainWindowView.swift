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
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )

            DetailRouter(selection: selection)
                .environmentObject(chrome)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, chrome.actions.isEmpty ? 20 : 56)
                .padding(.bottom, 20)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .overlay(alignment: .topTrailing) {
            if !chrome.actions.isEmpty {
                windowActionBar
                    .padding(.top, 10)
                    .padding(.trailing, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
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
        }
    }

    private func chromeActionLabel(_ action: WindowChromeAction) -> some View {
        HStack(spacing: 6) {
            Image(systemName: action.systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(action.title)
                .font(.system(size: 12, weight: action.isPrimary ? .semibold : .medium))
        }
        .foregroundStyle(action.isPrimary ? Color.white : Color.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(action.isPrimary ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.ultraThinMaterial))
        )
    }
}

// MacOnboardingSheet and MacToast are implemented in their own files under RelayMac/Views/.
