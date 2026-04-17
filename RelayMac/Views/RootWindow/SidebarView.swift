//
//  SidebarView.swift
//  RelayMac
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.Group.allCases, id: \.rawValue) { group in
                Section(group.rawValue) {
                    ForEach(itemsIn(group)) { item in
                        Label(item.title, systemImage: item.systemImage)
                            .tag(item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
    }

    private func itemsIn(_ group: SidebarItem.Group) -> [SidebarItem] {
        SidebarItem.allCases.filter { $0.group == group }
    }
}

#Preview {
    @Previewable @State var selection: SidebarItem? = .home
    return SidebarView(selection: $selection)
        .frame(width: 220, height: 400)
}
