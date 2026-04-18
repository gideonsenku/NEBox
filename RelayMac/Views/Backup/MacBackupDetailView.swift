//
//  MacBackupDetailView.swift
//  RelayMac
//

import AnyCodable
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
    @State private var showDeleteConfirm: Bool = false
    @State private var remoteBakData: AnyCodable?
    @State private var isLoadingBak: Bool = false
    @State private var loadError: String?

    /// Pretty-printed JSON cached off the main thread so large backups don't block rendering.
    @State private var cachedJSON: String?
    @State private var cachedByteCount: Int = 0
    @State private var isEncodingPreview: Bool = false
    @State private var encodeTaskID: UUID = UUID()

    private static let previewCharLimit: Int = 200_000

    private var bak: GlobalBackup? {
        boxModel.boxData.globalbaks?.first(where: { $0.id == bakId })
    }

    /// Remote-fetched data (preferred) falling back to whatever was embedded in the list payload.
    private var resolvedBak: AnyCodable? {
        remoteBakData ?? bak?.bak
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
        WorkbenchPageScroll {
            hero(for: bak)
            nameSection(for: bak)
            metaSection(for: bak)
            contentSection(for: bak)
            dangerSection(for: bak)
        }
        .toolbar { toolbar(for: bak) }
        .confirmationDialog(
            "确认恢复？",
            isPresented: $showRevertConfirm,
            titleVisibility: .visible
        ) {
            Button("恢复", role: .destructive) { revert(bak) }
            Button("取消", role: .cancel) {}
        } message: {
            Text("恢复将用此备份覆盖当前 BoxJS 数据。该操作不可撤销。")
        }
        .confirmationDialog(
            "确认删除此备份？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) { delete(bak) }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作不可恢复。")
        }
        .onAppear {
            nameDraft = bak.name
            loadBakData(for: bak)
        }
    }

    private func hero(for bak: GlobalBackup) -> some View {
        WorkbenchSectionBlock(title: "备份") {
            VStack(spacing: 10) {
                Image(systemName: "externaldrive.badge.icloud")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text(bak.name).font(.title2).bold()
                if let t = bak.createTime {
                    Text(formatTime(t))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func nameSection(for bak: GlobalBackup) -> some View {
        WorkbenchSectionBlock(title: "名称") {
            TextField("备份名称", text: $nameDraft, onCommit: {
                saveName(for: bak)
            })
            .textFieldStyle(.roundedBorder)
            Button("保存名称") { saveName(for: bak) }
                .disabled(nameDraft == bak.name || nameDraft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @ViewBuilder
    private func metaSection(for bak: GlobalBackup) -> some View {
        WorkbenchSectionBlock(title: "信息") {
            LabeledContent("备份索引") {
                Text(bak.id)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let tags = bak.tags?.filter({ !$0.isEmpty }), !tags.isEmpty {
                LabeledContent("标签") {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contentSection(for bak: GlobalBackup) -> some View {
        WorkbenchSectionBlock(
            title: "内容预览",
            subtitle: cachedByteCount > 0 ? byteDescription(cachedByteCount) : nil,
        ) {
            Group {
                if isLoadingBak {
                    placeholderRow("加载中…", withSpinner: true)
                } else if let loadError {
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text(loadError).font(.caption).foregroundStyle(.secondary)
                        Button("重试") { loadBakData(for: bak, force: true) }
                            .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else if resolvedBak == nil {
                    Text("（空）").foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if isEncodingPreview && cachedJSON == nil {
                    placeholderRow("正在生成预览…", withSpinner: true)
                } else if let cachedJSON {
                    previewBody(for: cachedJSON)
                } else {
                    placeholderRow("无法生成预览", withSpinner: false)
                }
            }
        } accessory: {
            if isLoadingBak || isEncodingPreview {
                ProgressView().controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func previewBody(for json: String) -> some View {
        let truncated = json.count > Self.previewCharLimit
        let displayed = truncated ? String(json.prefix(Self.previewCharLimit)) + "\n…\n(已截断，点击“复制 JSON”或“导出…”查看完整内容)" : json
        VStack(alignment: .leading, spacing: 6) {
            if truncated {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                    Text("内容较大，预览仅显示前 \(Self.previewCharLimit / 1000)K 字符")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            MacPlainTextView(text: displayed)
                .frame(minHeight: 240, maxHeight: 420)
        }
    }

    private func placeholderRow(_ text: String, withSpinner: Bool) -> some View {
        HStack(spacing: 8) {
            if withSpinner {
                ProgressView().controlSize(.small)
            }
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func byteDescription(_ bytes: Int) -> String {
        if bytes > 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / 1_048_576.0)
        } else if bytes > 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        }
        return "\(bytes) B"
    }

    private func dangerSection(for bak: GlobalBackup) -> some View {
        WorkbenchSectionBlock(title: "危险操作") {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("删除此备份", systemImage: "trash")
            }
            Text("删除后此备份将无法找回。")
                .font(.caption)
                .foregroundStyle(.secondary)
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
            .disabled(resolvedBak == nil)

            Button {
                copyJSON()
            } label: {
                Label("复制 JSON", systemImage: "doc.on.doc")
            }
            .disabled(resolvedBak == nil)

            Button {
                exportJSON(for: bak)
            } label: {
                Label("导出…", systemImage: "square.and.arrow.up")
            }
            .disabled(resolvedBak == nil)
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
            let stillExists = boxModel.boxData.globalbaks?.contains(where: { $0.id == bak.id }) ?? false
            if stillExists && bak.createTime == beforeTime {
                return
            }
            dismiss()
        }
    }

    private func delete(_ bak: GlobalBackup) {
        Task { @MainActor in
            await boxModel.delGlobalBak(id: bak.id)
            let stillExists = boxModel.boxData.globalbaks?.contains(where: { $0.id == bak.id }) ?? false
            if !stillExists {
                toastManager.showToast(message: "已删除")
                dismiss()
            }
        }
    }

    private func copyJSON() {
        guard let string = cachedJSON ?? resolvedBak.flatMap(encode) else {
            toastManager.showToast(message: "编码失败")
            return
        }
        PlatformBridge.copyToPasteboard(string)
        toastManager.showToast(message: "已复制 JSON")
    }

    private func exportJSON(for bak: GlobalBackup) {
        guard let string = cachedJSON ?? resolvedBak.flatMap(encode),
              let data = string.data(using: .utf8) else {
            toastManager.showToast(message: "编码失败")
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(bak.name)_\(bak.id).json"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
            toastManager.showToast(message: "已导出")
        } catch {
            toastManager.showToast(message: "导出失败：\(error.localizedDescription)")
        }
    }

    // MARK: - Remote data

    private func loadBakData(for bak: GlobalBackup, force: Bool = false) {
        if !force, remoteBakData != nil {
            encodePreview()
            return
        }
        if !force, bak.bak != nil {
            encodePreview()
            return
        }
        isLoadingBak = true
        loadError = nil
        Task {
            do {
                let data: AnyCodable = try await NetworkProvider.request(.loadGlobalBak(id: bak.id))
                await MainActor.run {
                    remoteBakData = data
                    isLoadingBak = false
                    encodePreview()
                }
            } catch {
                await MainActor.run {
                    isLoadingBak = false
                    loadError = "加载备份内容失败：\(error.localizedDescription)"
                }
                appLog(.error, category: .viewModel, "Failed to load backup data: \(error)")
            }
        }
    }

    /// Encode the resolved bak to pretty JSON on a background thread so large
    /// payloads (multi-MB) don't freeze the UI on layout.
    private func encodePreview() {
        guard let payload = resolvedBak else { return }
        cachedJSON = nil
        cachedByteCount = 0
        isEncodingPreview = true
        let taskID = UUID()
        encodeTaskID = taskID
        Task.detached(priority: .userInitiated) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let string: String? = {
                guard let data = try? encoder.encode(payload) else { return nil }
                return String(data: data, encoding: .utf8)
            }()
            let bytes = string?.utf8.count ?? 0
            await MainActor.run {
                guard taskID == encodeTaskID else { return }
                cachedJSON = string
                cachedByteCount = bytes
                isEncodingPreview = false
            }
        }
    }

    // MARK: - Helpers

    private func encode(_ value: AnyCodable) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFallback = ISO8601DateFormatter()
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    private func formatTime(_ iso: String) -> String {
        if let date = Self.isoFractional.date(from: iso) {
            return Self.displayFormatter.string(from: date)
        }
        if let date = Self.isoFallback.date(from: iso) {
            return Self.displayFormatter.string(from: date)
        }
        return iso
    }
}

// MARK: - NSTextView bridge

/// Read-only monospaced text viewer backed by NSTextView. Uses AppKit's
/// lazy layout so multi-megabyte JSON scrolls smoothly where a SwiftUI
/// `Text` would hang on layout.
private struct MacPlainTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = .textBackgroundColor

        if let textView = scroll.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.isRichText = false
            textView.drawsBackground = true
            textView.backgroundColor = .textBackgroundColor
            textView.textColor = .labelColor
            textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            textView.usesFindBar = true
            textView.isHorizontallyResizable = false
            textView.textContainerInset = NSSize(width: 8, height: 8)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.lineFragmentPadding = 2
            textView.string = text
        }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            textView.scroll(.zero)
        }
    }
}
