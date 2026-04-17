//
//  EditAvatarPopover.swift
//  RelayMac
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct EditAvatarPopover: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.dismiss) private var dismiss

    /// Notifies parent when a local avatar was saved (so parent can refresh).
    var onLocalChanged: () -> Void = {}

    @State private var urlDraft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("更换头像").font(.headline)

            Button {
                pickLocalImage()
            } label: {
                Label("从本地选择图片", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Divider()

            Text("或粘贴图片 URL").font(.subheadline).bold()
            TextField("https://...", text: $urlDraft)
                .textFieldStyle(.roundedBorder)
                .font(.system(.callout, design: .monospaced))

            HStack {
                if AvatarStorage.exists {
                    Button("清除本地头像", role: .destructive) {
                        AvatarStorage.delete()
                        onLocalChanged()
                        toastManager.showToast(message: "已清除本地头像")
                        dismiss()
                    }
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存 URL") { saveURL() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(urlDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            urlDraft = boxModel.boxData.usercfgs?.icon ?? ""
        }
    }

    // MARK: - Actions

    private func pickLocalImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic]
        panel.allowsMultipleSelection = false
        panel.message = "选择头像图片"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let image = PlatformImage(contentsOfFile: url.path) else {
            toastManager.showToast(message: "无法读取图片")
            return
        }
        if AvatarStorage.save(image) {
            toastManager.showToast(message: "已保存本地头像")
            onLocalChanged()
            dismiss()
        } else {
            toastManager.showToast(message: "头像保存失败")
        }
    }

    private func saveURL() {
        let trimmed = urlDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { @MainActor in
            let result = await boxModel.updateDataAsync(path: "usercfgs.icon", data: trimmed)
            switch result {
            case .success:
                toastManager.showToast(message: "头像 URL 已保存")
            case .failure(let err):
                toastManager.showToast(message: "保存失败：\(err.localizedDescription)")
            }
            dismiss()
        }
    }
}
