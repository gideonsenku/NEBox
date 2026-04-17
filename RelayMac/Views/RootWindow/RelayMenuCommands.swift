//
//  RelayMenuCommands.swift
//  RelayMac
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RelayMenuCommands: Commands {
    @ObservedObject var boxModel: BoxJsViewModel
    @ObservedObject var apiManager: ApiManager

    var body: some Commands {
        // Remove File → New (single window app)
        CommandGroup(replacing: .newItem) {}

        // Help menu — link to project repo
        CommandGroup(replacing: .help) {
            Button("Relay 项目主页") {
                if let url = URL(string: "https://github.com/gideonsenku") {
                    PlatformBridge.open(url)
                }
            }
        }

        CommandMenu("数据") {
            Button("刷新") { boxModel.fetchData() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!apiManager.isApiUrlSet())

            Divider()

            Button("导入备份…") { importBackup() }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(!apiManager.isApiUrlSet())

            Button("清空服务器地址", role: .destructive) {
                apiManager.apiUrl = nil
            }
        }
    }

    @MainActor
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
            return
        }

        Task { @MainActor in
            await boxModel.impGlobalBak(bakData: jsonString)
        }
    }
}
