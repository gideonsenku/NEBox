//
//  MacBackupDetailView.swift
//  RelayMac
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacBackupDetailView: View {
    let bakId: String

    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.dismiss) private var dismiss

    @State private var nameDraft: String = ""
    @State private var showRevertConfirm: Bool = false

    private var bak: GlobalBackup? {
        boxModel.boxData.globalbaks?.first(where: { $0.id == bakId })
    }

    var body: some View {
        Group {
            if let bak {
                content(for: bak)
            } else {
                ContentUnavailableView(
                    "备份不存在",
                    systemImage: "exclamationmark.triangle",
                    description: Text("id: \(bakId)")
                )
            }
        }
        .navigationTitle(bak?.name ?? "备份详情")
    }

    // MARK: - Content

    private func content(for bak: GlobalBackup) -> some View {
        Form {
            hero(for: bak)
            nameSection(for: bak)
            contentSection(for: bak)
        }
        .formStyle(.grouped)
        .toolbar { toolbar(for: bak) }
        .alert("确认恢复？", isPresented: $showRevertConfirm) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive) { revert(bak) }
        } message: {
            Text("恢复将用此备份覆盖当前 BoxJS 数据。该操作不可撤销。")
        }
        .onAppear { nameDraft = bak.name }
    }

    private func hero(for bak: GlobalBackup) -> some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "externaldrive.badge.icloud")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text(bak.name).font(.title2).bold()
                if let t = bak.createTime {
                    Text(t).font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func nameSection(for bak: GlobalBackup) -> some View {
        Section("名称") {
            TextField("备份名称", text: $nameDraft, onCommit: {
                saveName(for: bak)
            })
            .textFieldStyle(.roundedBorder)
            Button("保存名称") { saveName(for: bak) }
                .disabled(nameDraft == bak.name)
        }
    }

    @ViewBuilder
    private func contentSection(for bak: GlobalBackup) -> some View {
        Section("内容预览") {
            ScrollView {
                Text(jsonPreview(for: bak))
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
            }
            .frame(maxHeight: 320)
        }
    }

    @ToolbarContentBuilder
    private func toolbar(for bak: GlobalBackup) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showRevertConfirm = true
            } label: {
                Label("恢复", systemImage: "arrow.counterclockwise")
            }

            Button {
                copyJSON(for: bak)
            } label: {
                Label("复制 JSON", systemImage: "doc.on.doc")
            }

            Button {
                exportJSON(for: bak)
            } label: {
                Label("导出…", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Actions

    private func saveName(for bak: GlobalBackup) {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != bak.name else { return }
        Task { @MainActor in
            await boxModel.updateGlobalBak(id: bak.id, name: trimmed)
            toastManager.showToast(message: "名称已保存")
        }
    }

    private func revert(_ bak: GlobalBackup) {
        toastManager.showLoading(message: "恢复中…")
        let beforeTime = bak.createTime
        Task { @MainActor in
            await boxModel.revertGlobalBak(id: bak.id)
            toastManager.hideLoading()
            // Only pop back if the revert plausibly succeeded — we can't get
            // a Result back from the fire-and-forget ViewModel call, so use
            // the heuristic: the backup still exists AND server refetched.
            // The ViewModel surfaces errors via toast inside `optimistic`,
            // so if we reach here and the backup is gone, assume success.
            let stillExists = boxModel.boxData.globalbaks?.contains(where: { $0.id == bak.id }) ?? false
            if stillExists && bak.createTime == beforeTime {
                // Revert may have failed (backup unchanged); stay on page so
                // the user can see the ViewModel's error toast and retry.
                return
            }
            dismiss()
        }
    }

    private func copyJSON(for bak: GlobalBackup) {
        guard let string = jsonString(for: bak) else {
            toastManager.showToast(message: "编码失败")
            return
        }
        PlatformBridge.copyToPasteboard(string)
        toastManager.showToast(message: "已复制 JSON")
    }

    private func exportJSON(for bak: GlobalBackup) {
        guard let string = jsonString(for: bak),
              let data = string.data(using: .utf8) else {
            toastManager.showToast(message: "编码失败")
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(bak.name).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
            toastManager.showToast(message: "已导出")
        } catch {
            toastManager.showToast(message: "导出失败：\(error.localizedDescription)")
        }
    }

    // MARK: - JSON helpers

    private func jsonString(for bak: GlobalBackup) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(bak)).flatMap { String(data: $0, encoding: .utf8) }
    }

    private func jsonPreview(for bak: GlobalBackup) -> String {
        jsonString(for: bak) ?? "（无法编码）"
    }
}
