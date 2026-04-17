//
//  RenameSessionPopover.swift
//  RelayMac
//

import SwiftUI

struct RenameSessionPopover: View {
    let session: Session
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.dismiss) private var dismiss

    @State private var nameDraft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重命名会话").font(.headline)
            TextField("名称", text: $nameDraft, onCommit: save)
                .textFieldStyle(.roundedBorder)
                .focused($focused)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("完成", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        nameDraft.trimmingCharacters(in: .whitespaces).isEmpty ||
                        nameDraft == session.name
                    )
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            nameDraft = session.name
            DispatchQueue.main.async { focused = true }
        }
    }

    private func save() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != session.name else {
            dismiss()
            return
        }
        var updated = session
        updated.name = trimmed
        boxModel.updateAppSession(updated)
        toastManager.showToast(message: "已重命名")
        dismiss()
    }
}
