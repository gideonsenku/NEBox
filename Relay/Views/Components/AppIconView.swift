//
//  AppIconView.swift
//  Relay
//

import SwiftUI
import SDWebImageSwiftUI

/// Adaptive app icon that switches between light/dark variants from `AppModel.icons`.
/// Uses standard iOS home-screen icon sizing: 60pt with ~13.4pt continuous corner radius.
struct AppIconView: View {
    let app: AppModel
    var size: CGFloat = 60

    /// iOS home-screen corner radius ratio ≈ 0.2237
    private var cornerRadius: CGFloat { size * 0.2237 }

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        if let url = app.adaptiveIconURL(isDark: isDark) {
            ZStack {
                // Dark mode alpha icons need a visible background
                if isDark {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.bgCard)
                }

                WebImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderView
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            placeholderView
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.bgMuted)
            .overlay(
                Image(systemName: "app.fill")
                    .foregroundColor(.textTertiary)
            )
    }
}
