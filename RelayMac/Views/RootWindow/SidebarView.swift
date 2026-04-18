//
//  SidebarView.swift
//  RelayMac
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    let isConnected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navSections
            footer
        }
        .padding(.horizontal, 10)
        .padding(.top, 36)
        .padding(.bottom, 12)
        .frame(width: 210)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var navSections: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(SidebarItem.Group.allCases, id: \.rawValue) { group in
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 4)

                    ForEach(SidebarItem.allCases.filter { $0.group == group }) { item in
                        sidebarButton(for: item)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func sidebarButton(for item: SidebarItem) -> some View {
        let isSelected = selection == item
        return Button {
            selection = item
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .frame(width: 16)
                Text(item.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.07) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
    }
}

#Preview {
    @Previewable @State var selection: SidebarItem? = .home
    return SidebarView(selection: $selection, isConnected: true)
        .environment(\.colorScheme, .light)
        .frame(width: 220, height: 400)
}
