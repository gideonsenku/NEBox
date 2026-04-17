//
//  MacAboutView.swift
//  RelayMac
//

import SwiftUI

struct MacAboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Relay for macOS")
                .font(.largeTitle).bold()
            Text(version)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("BoxJS 原生 macOS 客户端")
                .font(.body)
                .foregroundStyle(.secondary)
            Divider().padding(.horizontal, 80)
            Text("© 2026 Senku")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(v) (\(b))"
    }
}
