//
//  StatsCard.swift
//  RelayMac
//

import SwiftUI

struct StatsCard: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
            Text("\(value)")
                .font(.largeTitle).bold()
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(background)
    }

    @ViewBuilder
    private var background: some View {
        if #available(macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        }
    }
}
