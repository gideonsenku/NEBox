//
//  MacLogViewerView.swift
//  RelayMac
//

import SwiftUI

struct MacLogViewerView: View {
    @EnvironmentObject var toastManager: ToastManager

    @State private var logText: String = ""
    @State private var filter: String = ""

    private var filteredText: String {
        let needle = filter.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return logText }
        return logText
            .components(separatedBy: "\n")
            .filter { $0.localizedCaseInsensitiveContains(needle) }
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            Divider()
            ScrollView {
                Text(filteredText.isEmpty ? "（暂无日志）" : filteredText)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
        }
        .onAppear(perform: refresh)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            TextField("过滤", text: $filter)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)
            Button("刷新") { refresh() }
            Button("复制全部") {
                PlatformBridge.copyToPasteboard(filteredText)
                toastManager.showToast(message: "已复制")
            }
            Button("清空", role: .destructive) {
                LogManager.shared.clearLogs()
                logText = ""
            }
            Spacer()
            Text(byteCountDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var byteCountDescription: String {
        let bytes = logText.utf8.count
        if bytes > 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / 1_048_576.0)
        } else if bytes > 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        }
        return "\(bytes) B"
    }

    private func refresh() {
        logText = LogManager.shared.readLogs()
    }
}
