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
    @EnvironmentObject var chrome: WindowChromeModel

    @State private var showDeleteConfirm: Bool = false
    @State private var deleteTarget: GlobalBackup?
    @State private var showRestoreConfirm: Bool = false
    @State private var restoreTarget: GlobalBackup?
    @State private var showNewBackupAlert: Bool = false
    @State private var newBackupName: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header
                backupList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationDestination(for: MacRoute.self) { route in
                MacRouteDestination(route: route)
            }
        }
        .onAppear { chrome.clear() }
        .confirmationDialog(
            "确认删除此备份？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible,
            presenting: deleteTarget
        ) { target in
            Button("删除", role: .destructive) {
                Task { await boxModel.delGlobalBak(id: target.id) }
            }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog(
            "恢复此备份将覆盖当前数据",
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible,
            presenting: restoreTarget
        ) { target in
            Button("恢复", role: .destructive) {
                Task { await boxModel.revertGlobalBak(id: target.id) }
            }
            Button("取消", role: .cancel) {}
        } message: { _ in
            Text("当前服务器的数据将被该备份覆盖，无法撤销。")
        }
        .alert("创建备份", isPresented: $showNewBackupAlert) {
            TextField("备份名称（可选）", text: $newBackupName)
            Button("创建") {
                let name = newBackupName.trimmingCharacters(in: .whitespacesAndNewlines)
                newBackupName = ""
                Task { await boxModel.saveGlobalBak(name: name.isEmpty ? nil : name) }
            }
            Button("取消", role: .cancel) { newBackupName = "" }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("备份中心")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 16)

            importButton
            createButton
        }
    }

    private var importButton: some View {
        Button(action: importBackup) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("导入备份")
    }

    private var createButton: some View {
        Button {
            showNewBackupAlert = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor)
                )
                .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .help("创建备份")
    }

    // MARK: - Backup List

    @ViewBuilder
    private var backupList: some View {
        if let backups = boxModel.boxData.globalbaks, !backups.isEmpty {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(backups.enumerated()), id: \.element.id) { pair in
                        BackupCard(
                            bak: pair.element,
                            isLatest: pair.offset == 0,
                            onRestore: {
                                restoreTarget = pair.element
                                showRestoreConfirm = true
                            },
                            onExport: { exportBackup(pair.element) },
                            onDelete: {
                                deleteTarget = pair.element
                                showDeleteConfirm = true
                            }
                        )
                    }
                }
                .padding(.bottom, 4)
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "archivebox")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("暂无备份")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text("点击右上角的 + 创建一个新备份")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Backup Card

private struct BackupCard: View {
    let bak: GlobalBackup
    let isLatest: Bool
    let onRestore: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink(value: MacRoute.backup(id: bak.id)) {
                HStack(spacing: 14) {
                    iconBox
                    info
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            actionRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var iconBox: some View {
        Image(systemName: "archivebox.fill")
            .font(.system(size: 18))
            .foregroundStyle(isLatest ? Color.white : Color.secondary)
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isLatest ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.primary.opacity(0.06)))
            )
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bak.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            HStack(spacing: 12) {
                if let t = bak.createTime, !t.isEmpty {
                    Text(t)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                if let tags = bak.tags, !tags.isEmpty {
                    Text(tags.joined(separator: " · "))
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            iconButton(systemName: "arrow.counterclockwise", tint: .secondary, help: "恢复备份", action: onRestore)
            iconButton(systemName: "square.and.arrow.up", tint: .secondary, help: "导出备份", action: onExport)
            iconButton(systemName: "trash", tint: .red, help: "删除备份", filled: false, action: onDelete)
        }
    }

    private func iconButton(
        systemName: String,
        tint: Color,
        help: String,
        filled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(filled ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear))
                )
                .overlay(
                    Group {
                        if filled {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
