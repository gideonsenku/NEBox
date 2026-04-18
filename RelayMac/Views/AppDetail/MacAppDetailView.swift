//
//  MacAppDetailView.swift
//  RelayMac
//

import AnyCodable
import SwiftUI

struct MacAppDetailView: View {
    let app: AppModel
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var chrome: WindowChromeModel

    @State private var drafts: [String: AnyCodable?] = [:]
    @State private var saving: Bool = false
    @State private var renameTarget: Session?
    @State private var latestScriptName: String?
    @State private var latestScriptResult: ScriptResp?
    @State private var showScriptInspector: Bool = false
    @State private var showImportSession: Bool = false
    @State private var showClearConfirm: Bool = false

    var body: some View {
        WorkbenchPageScroll {
            basicsSection
            settingsSection
            sessionSection
            scriptsSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    save()
                } label: {
                    if saving {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("保存", systemImage: "tray.and.arrow.down")
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(drafts.isEmpty || saving)
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("导入会话") {
                        showImportSession = true
                    }
                    Button("复制数据") {
                        copyAppDatas()
                    }
                    .disabled(appKeys.isEmpty)
                    Button("复制会话") {
                        if let session = currentSession {
                            copySession(session)
                        }
                    }
                    .disabled(currentSession == nil)
                    Divider()
                    Button("清除数据", role: .destructive) {
                        showClearConfirm = true
                    }
                    .disabled(appKeys.isEmpty)
                } label: {
                    Label("更多", systemImage: "ellipsis.circle")
                }
            }
        }
        .navigationTitle(app.name)
        .navigationSubtitle(app.author.asHandle)
        .onAppear {
            chrome.clear()
            primeDrafts()
        }
        .popover(item: $renameTarget, arrowEdge: .trailing) { session in
            RenameSessionPopover(session: session)
                .environmentObject(boxModel)
                .environmentObject(toastManager)
        }
        .inspector(isPresented: $showScriptInspector) {
            if let scriptName = latestScriptName,
               let scriptResult = latestScriptResult {
                MacScriptResultInspector(
                    scriptName: scriptName,
                    result: scriptResult,
                    onClose: { showScriptInspector = false }
                )
            } else {
                ContentUnavailableView(
                    "暂无脚本结果",
                    systemImage: "terminal",
                    description: Text("运行脚本后会在这里显示输出")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .inspectorColumnWidth(min: 280, ideal: 360, max: 520)
        .sheet(isPresented: $showImportSession) {
            NavigationStack {
                MacImportSessionView()
                    .environmentObject(boxModel)
                    .environmentObject(toastManager)
            }
            .frame(minWidth: 640, minHeight: 420)
        }
        .confirmationDialog(
            "确定要清除这个应用的所有数据吗？",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("清除", role: .destructive) {
                boxModel.clearAppDatas(app: app)
                toastManager.showToast(message: "已清除")
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var basicsSection: some View {
        WorkbenchSectionBlock(title: "基础") {
            LabeledContent("名称") { Text(app.name) }
            LabeledContent("作者") { Text(app.author) }
            if let repo = app.repo, !repo.isEmpty, let url = URL(string: repo) {
                LabeledContent("Repo") {
                    Link(repo, destination: url)
                        .font(.footnote)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        if app.hasDescription {
            WorkbenchSectionBlock(title: "说明") {
                descriptionContent
            }
        }
    }

    @ViewBuilder
    private var descriptionContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let desc = app.desc, !desc.isEmpty {
                Text(desc)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let descs = app.descs, !descs.isEmpty {
                ForEach(descs, id: \.self) { line in
                    Text(line)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if let html = app.desc_html, !html.isEmpty {
                htmlText(html)
            }
            if let descs_html = app.descs_html, !descs_html.isEmpty {
                htmlText(descs_html.joined(separator: "<br>"))
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func htmlText(_ html: String) -> some View {
        if let attributed = Self.attributedString(fromHTML: html) {
            Text(attributed)
                .font(.callout)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(html)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Parses HTML into an `AttributedString` for SwiftUI `Text`. Drops the
    /// HTML-defaulted black foreground color so the text inherits from the
    /// surrounding environment (important for dark mode).
    private static func attributedString(fromHTML html: String) -> AttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let ns = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }
        let mutable = NSMutableAttributedString(attributedString: ns)
        let range = NSRange(location: 0, length: mutable.length)
        mutable.removeAttribute(.foregroundColor, range: range)
        return try? AttributedString(mutable, including: \.swiftUI)
    }

    @ViewBuilder
    private var settingsSection: some View {
        if let settings = app.settings, !settings.isEmpty {
            WorkbenchSectionBlock(title: "设置") {
                ForEach(settings, id: \.id) { setting in
                    SettingRowMac(
                        setting: setting,
                        value: binding(for: setting)
                    )
                }
            }
        } else {
            WorkbenchSectionBlock(title: "设置") {
                Text("此应用没有可编辑项")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sessionSection: some View {
        SessionListSection(
            app: app,
            sessions: sessionsForThisApp,
            currentSessionId: currentSessionId,
            onRenameRequested: { renameTarget = $0 }
        )
    }

    @ViewBuilder
    private var scriptsSection: some View {
        if let scripts = app.scripts, !scripts.isEmpty {
            ScriptsSection(scripts: scripts) { script, result in
                latestScriptName = script.name
                latestScriptResult = result
                showScriptInspector = true
            }
        }
    }

    // MARK: - Derived data

    private var sessionsForThisApp: [Session] {
        boxModel.boxData.sessions.filter { $0.appId == app.id }
    }

    private var currentSessionId: String? {
        boxModel.boxData.curSessions?[app.id]
    }

    // MARK: - Drafts

    private func primeDrafts() {
        guard drafts.isEmpty, let settings = app.settings else { return }
        for setting in settings {
            if let existing = boxModel.boxData.datas[setting.id] {
                drafts[setting.id] = existing
            } else if let val = setting.val {
                drafts[setting.id] = val
            } else {
                drafts[setting.id] = nil
            }
        }
    }

    private func binding(for setting: Setting) -> Binding<AnyCodable?> {
        Binding(
            get: { drafts[setting.id] ?? setting.val },
            set: { drafts[setting.id] = $0 }
        )
    }

    private func save() {
        saving = true
        let params: [SessionData] = drafts.map { SessionData(key: $0.key, val: $0.value) }
        boxModel.saveData(params: params)
        toastManager.showToast(message: "已提交")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            saving = false
        }
    }

    // MARK: - Session ops

    private var appKeys: [String] {
        app.keys ?? []
    }

    private var currentSession: Session? {
        guard let id = currentSessionId else { return nil }
        return boxModel.boxData.sessions.first { $0.id == id }
    }

    private func copyAppDatas() {
        var result: [String: String] = [:]
        for key in appKeys {
            let val = boxModel.boxData.datas[key] ?? nil
            result[key] = dataValString(val)
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result),
              let str = String(data: jsonData, encoding: .utf8) else { return }
        PlatformBridge.copyToPasteboard(str)
        toastManager.showToast(message: "已复制数据")
    }

    private func copySession(_ session: Session) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(session),
              let str = String(data: data, encoding: .utf8) else { return }
        PlatformBridge.copyToPasteboard(str)
        toastManager.showToast(message: "已复制会话")
    }

    private func dataValString(_ val: AnyCodable?) -> String {
        guard let val else { return "" }
        if let str = val.value as? String { return str }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(val),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: val.value)
    }
}
