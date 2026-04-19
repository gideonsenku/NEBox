//
//  GlassAppCard.swift
//  RelayMac
//

import SDWebImageSwiftUI
import SwiftUI

/// Visual-only card for an `AppModel`. Wrap in `NavigationLink` or `Button`
/// at the call site to make it interactive.
struct GlassAppCard: View {
    let app: AppModel

    @AppStorage(MacIconAppearance.userDefaultsKey) private var iconAppearanceRaw: String = MacIconAppearance.auto.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            icon
            Text(app.name)
                .font(.callout).bold()
                .lineLimit(1)
            Text(app.author.isEmpty ? " " : app.author.asHandle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isHovering)
        .onHover { hovering in isHovering = hovering }
    }

    private var icon: some View {
        Group {
            if let url = preferredIconURL {
                WebImage(url: url)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var preferredIconURL: URL? {
        let appearance = MacIconAppearance(rawValue: iconAppearanceRaw) ?? .auto
        let isDark = appearance.isDark(systemIsDark: colorScheme == .dark)
        return app.adaptiveIconURL(isDark: isDark)
    }
}
