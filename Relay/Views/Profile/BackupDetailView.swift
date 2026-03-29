//
//  BackupDetailView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import AnyCodable

// MARK: - Backup Detail View

struct BackupDetailView: View {
    let backup: GlobalBackup

    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.presentationMode) var presentationMode

    @State private var editedName: String = ""
    @State private var bakData: AnyCodable? = nil
    @State private var isLoadingBak = false
    @State private var exportFileURL: URL? = nil
    @State private var showExportShare = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BackupInfoSection(
                    backup: backup,
                    editedName: $editedName,
                    onNameSubmit: updateBackupName
                )

                BackupActionSection(
                    isLoadingBak: isLoadingBak,
                    hasBakData: (bakData ?? backup.bak) != nil,
                    hasExportFile: exportFileURL != nil,
                    onRestore: restoreBackup,
                    onCopy: copyBackupData,
                    onExport: { showExportShare = true }
                )

                BackupDangerSection(onDelete: { showDeleteConfirm = true })
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(backup.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            ActivityViewPresenter(isPresented: $showExportShare, items: exportFileURL.map { [$0] } ?? [])
        )
        .onAppear {
            editedName = backup.name
            prepareExportFile(from: backup.bak)
            loadBakData()
        }
        .alert("确认删除此备份？", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive, action: deleteBackup)
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作不可恢复")
        }
    }
}

// MARK: - BackupDetailView Actions

private extension BackupDetailView {
    func updateBackupName() {
        Task {
            await boxModel.updateGlobalBak(id: backup.id, name: editedName)
            toastManager.showToast(message: "已更新")
        }
    }

    func restoreBackup() {
        Task {
            await boxModel.revertGlobalBak(id: backup.id)
            toastManager.showToast(message: "恢复成功!")
            presentationMode.wrappedValue.dismiss()
        }
    }

    func copyBackupData() {
        if let bak = bakData ?? backup.bak {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(bak),
               let str = String(data: data, encoding: .utf8) {
                copyToClipboard(text: str)
                toastManager.showToast(message: "已复制备份数据")
            }
        } else {
            toastManager.showToast(message: "备份数据加载中...")
        }
    }

    func deleteBackup() {
        Task {
            await boxModel.delGlobalBak(id: backup.id)
            toastManager.showToast(message: "已删除")
            presentationMode.wrappedValue.dismiss()
        }
    }

    func loadBakData() {
        guard bakData == nil, backup.bak == nil else { return }
        isLoadingBak = true
        Task {
            do {
                let data: AnyCodable = try await NetworkProvider.request(.loadGlobalBak(id: backup.id))
                await MainActor.run {
                    bakData = data
                    isLoadingBak = false
                    prepareExportFile(from: data)
                }
            } catch {
                await MainActor.run { isLoadingBak = false }
                appLog(.error, category: .viewModel, "Failed to load backup data: \(error)")
            }
        }
    }

    func prepareExportFile(from bak: AnyCodable?) {
        guard let bak = bak, exportFileURL == nil else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(bak) {
            let fileName = "\(backup.name)_\(backup.id).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try? data.write(to: tempURL)
            exportFileURL = tempURL
        }
    }
}

// MARK: - Backup Info Section

private struct BackupInfoSection: View {
    let backup: GlobalBackup
    @Binding var editedName: String
    let onNameSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            BackupHeroArea(backup: backup, editedName: $editedName, onNameSubmit: onNameSubmit)

            if let createTime = backup.createTime {
                Divider()
                InfoRow(label: "备份索引", value: backup.id)
            }

            if let tags = backup.tags, !tags.isEmpty {
                Divider()
                TagsRow(tags: tags)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 12, y: 2)
    }
}

// MARK: - Backup Hero Area

private struct BackupHeroArea: View {
    let backup: GlobalBackup
    @Binding var editedName: String
    let onNameSubmit: () -> Void

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFallback = ISO8601DateFormatter()
    private static let heroDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentLight)
                    .frame(width: 72, height: 72)
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accent)
            }

            TextField("备份名称", text: $editedName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#1A1918"))
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit(onNameSubmit)

            if let createTime = backup.createTime {
                Text(Self.formatDate(createTime))
                    .font(.system(size: 13))
                    .foregroundColor(.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
    }

    private static func formatDate(_ isoString: String) -> String {
        if let date = isoFractional.date(from: isoString) {
            return heroDateFormatter.string(from: date)
        }
        if let date = isoFallback.date(from: isoString) {
            return heroDateFormatter.string(from: date)
        }
        return isoString
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color(.tertiaryLabel))
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

// MARK: - Tags Row

private struct TagsRow: View {
    let tags: [String]

    var body: some View {
        HStack {
            Text("标签")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(tags.filter { !$0.isEmpty }, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

// MARK: - Backup Action Section

private struct BackupActionSection: View {
    let isLoadingBak: Bool
    let hasBakData: Bool
    let hasExportFile: Bool
    let onRestore: () -> Void
    let onCopy: () -> Void
    let onExport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DetailActionRow(
                icon: "arrow.counterclockwise",
                title: "恢复此备份",
                subtitle: "将数据还原到此备份状态",
                action: onRestore
            )

            Divider()

            DetailActionRow(
                icon: "doc.on.doc",
                title: "复制备份数据",
                subtitle: "复制 JSON 数据到剪贴板",
                isLoading: isLoadingBak && !hasBakData,
                action: onCopy
            )

            Divider()

            DetailActionRow(
                icon: "square.and.arrow.down",
                title: "导出 JSON 文件",
                subtitle: "保存备份数据为本地文件",
                isLoading: isLoadingBak && !hasExportFile,
                isDisabled: !hasExportFile,
                action: onExport
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 12, y: 2)
    }
}

// MARK: - Detail Action Row

private struct DetailActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Backup Danger Section

private struct BackupDangerSection: View {
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("此操作不可恢复，请谨慎操作")
                .font(.system(size: 12))
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Button(action: onDelete) {
                Text("删除备份")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 12, y: 2)
    }
}

// MARK: - Activity View Presenter

/// Bridges UIActivityViewController into SwiftUI via a hidden UIViewController.
/// Compatible with iOS 15+.
private struct ActivityViewPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        if isPresented {
            guard host.presentedViewController == nil else { return }
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            ac.completionWithItemsHandler = { _, _, _, _ in
                isPresented = false
            }
            host.present(ac, animated: true)
        } else {
            if host.presentedViewController is UIActivityViewController {
                host.dismiss(animated: true)
            }
        }
    }
}
