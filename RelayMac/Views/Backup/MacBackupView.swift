//
//  MacBackupView.swift
//  RelayMac
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacBackupView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    var body: some View {
        NavigationStack {
            Form {
                importSection
                backupsSection
            }
            .formStyle(.grouped)
            .padding(10)
            .navigationTitle("备份")
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
        }
    }

    private var importSection: some View {
        Section("全局备份") {
            Button("导入备份 (JSON)…") { importBackup() }
                .buttonStyle(.borderedProminent)
            Text("选择一个 Relay/NEBox 导出的 JSON 文件合并到当前服务器。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var backupsSection: some View {
        Section("历史备份") {
            if let backups = boxModel.boxData.globalbaks, !backups.isEmpty {
                ForEach(backups) { bak in
                    NavigationLink(value: MacRoute.backup(id: bak.id)) {
                        BackupRow(bak: bak)
                    }
                    .contextMenu {
                        Button("导出…") { exportBackup(bak) }
                    }
                }
            } else {
                Text("暂无备份").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "选择要导入的 Relay 备份 JSON"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let jsonString = String(data: data, encoding: .utf8),
              !jsonString.isEmpty else {
            toastManager.showToast(message: "读取失败")
            return
        }

        toastManager.showLoading(message: "导入中…")
        Task { @MainActor in
            await boxModel.impGlobalBak(bakData: jsonString)
            toastManager.hideLoading()
        }
    }

    private func exportBackup(_ bak: GlobalBackup) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(bak.name).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(bak)
            try data.write(to: url, options: .atomic)
            toastManager.showToast(message: "已导出")
        } catch {
            toastManager.showToast(message: "导出失败：\(error.localizedDescription)")
        }
    }
}

private struct BackupRow: View {
    let bak: GlobalBackup

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.icloud")
                .font(.system(size: 22))
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(bak.name).font(.body)
                if let t = bak.createTime {
                    Text(t).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
