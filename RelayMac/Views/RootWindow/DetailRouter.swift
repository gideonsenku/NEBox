//
//  DetailRouter.swift
//  RelayMac
//

import SwiftUI

struct DetailRouter: View {
    let selection: SidebarItem?

    var body: some View {
        Group {
            switch selection {
            case .home:          MacHomeView()
            case .subscriptions: MacSubscribeListView()
            case .scripts:       MacScriptEditorView()
            case .dataViewer:    MacDataViewerView()
            case .logs:          MacLogViewerView()
            case .backup:        MacBackupView()
            case .preferences:   MacPreferencesView()
            case nil:            EmptySelectionView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("从侧边栏选择一项")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

// All detail views live in their own files under RelayMac/Views/.
