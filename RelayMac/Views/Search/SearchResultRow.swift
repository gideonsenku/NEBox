//
//  SearchResultRow.swift
//  RelayMac
//

import SDWebImageSwiftUI
import SwiftUI

struct SearchResultRow: View {
    let app: AppModel
    let isFavorite: Bool
    var onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.body).bold()
                        .lineLimit(1)
                    Text(app.id)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                if !app.author.isEmpty {
                    Text(app.author.asHandle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            .help(isFavorite ? "取消收藏" : "添加收藏")
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var icon: some View {
        if let urlString = app.icons.first,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            WebImage(url: url).resizable().scaledToFit()
        } else {
            ZStack {
                Color.secondary.opacity(0.1)
                Image(systemName: "app")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
