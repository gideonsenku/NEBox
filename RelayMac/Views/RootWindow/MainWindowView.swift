//
//  MainWindowView.swift
//  RelayMac
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var selection: SidebarItem? = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showOnboarding: Bool = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selection)
        } detail: {
            DetailRouter(selection: selection)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            boxModel.fetchData()
                        } label: {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                        .disabled(!apiManager.isApiUrlSet())
                        .keyboardShortcut("r", modifiers: .command)
                    }
                }
                .navigationTitle(selection?.title ?? "Relay")
        }
        .frame(minWidth: 900, minHeight: 560)
        .sheet(isPresented: $showOnboarding) {
            MacOnboardingSheet()
                .environmentObject(apiManager)
                .environmentObject(toastManager)
                .environmentObject(boxModel)
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
}

// MacOnboardingSheet and MacToast are implemented in their own files under RelayMac/Views/.
