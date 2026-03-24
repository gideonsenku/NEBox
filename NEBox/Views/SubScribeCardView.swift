//
//  SubScribeCardView.swift
//  BoxJs
//
//  Created by Senku on 8/6/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Foundation

struct SubScribeCardView: View {
    var item: AppSubCache
    var isLoading: Bool
    var isEditMode: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: name + icon
            HStack(alignment: .top) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                subIcon
            }

            Spacer()

            // Error badge
            if item.isErr == true {
                Text("异常")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(.bottom, 6)
            }

            // Bottom row: time + count
            HStack(alignment: .bottom) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(item.updateTime.isEmpty ? "N/A" : item.formatTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(item.apps.count)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
        }
        .padding(14)
        .frame(minHeight: 110)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .overlay(alignment: .topLeading) {
            if isEditMode {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(.darkGray))
                }
                .offset(x: -8, y: -8)
            }
        }
    }

    @ViewBuilder
    private var subIcon: some View {
        if let iconUrl = URL(string: item.icon), !item.icon.isEmpty {
            WebImage(url: iconUrl) { image in
                image.resizable()
            } placeholder: {
                iconPlaceholder
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            iconPlaceholder
        }
    }

    private var iconPlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray3))
            )
    }
}

struct SubScribeCard_Previews: View {
    @State var isLoading = false
    @State var previewItem = AppSubCache(
        id: "1",
        name: "Senku应用订阅",
        icon: "https://avatars1.githubusercontent.com/u/39037656?s=460&u=5843b86eae433868b6ade4ec23f8353fe7300df4&v=4&quot",
        author: "Senku",
        repo: "https://github.com/gideonsenku",
        updateTime: "01-21",
        apps: [],
        isErr: false,
        enable: true,
        url: "https://github.com/gideonsenku",
        raw: nil
    )

    var body: some View {
        SubScribeCardView(item: previewItem, isLoading: isLoading)
            .frame(width: 170)
    }
}

#Preview {
    SubScribeCard_Previews()
}
