//
//  MacImportSessionView.swift
//  RelayMac
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacImportSessionView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.dismiss) private var dismiss

    @State private var importSessionText: String = ""

    var body: some View {
        Form {
            Section("导入来源") {
                Button("从剪贴板粘贴") {
                    guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else {
                        toastManager.showToast(message: "剪贴板为空")
                        return
                    }
                    importSessionText = content
                }

                Button("从文件导入…") {
                    importFromFile()
                }
            }

            if !importSessionText.isEmpty {
                Section("数据预览") {
                    TextEditor(text: $importSessionText)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 220)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("导入会话")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("导入") {
                    performImport()
                }
                .disabled(importSessionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func importFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "选择 JSON 格式的会话文件"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8),
              !content.isEmpty else {
            toastManager.showToast(message: "读取失败")
            return
        }
        importSessionText = content
    }

    private func performImport() {
        let content = importSessionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        if boxModel.importSession(jsonString: content) {
            toastManager.showToast(message: "导入成功")
            dismiss()
        } else {
            toastManager.showToast(message: "导入失败，请检查 JSON 格式")
        }
    }
}
