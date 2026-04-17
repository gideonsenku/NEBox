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

    @State private var drafts: [String: AnyCodable?] = [:]
    @State private var saving: Bool = false
    @State private var renameTarget: Session?
    @State private var latestScriptName: String?
    @State private var latestScriptResult: ScriptResp?
    @State private var showScriptInspector: Bool = false

    var body: some View {
        Form {
            basicsSection
            settingsSection
            sessionSection
            scriptsSection
        }
        .formStyle(.grouped)
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
        }
        .navigationTitle(app.name)
        .navigationSubtitle(app.author.isEmpty ? "" : "@\(app.author)")
        .onAppear(perform: primeDrafts)
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
    }

    // MARK: - Sections

    private var basicsSection: some View {
        Section("基础") {
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
            if let desc = app.desc, !desc.isEmpty {
                Text(desc).font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        if let settings = app.settings, !settings.isEmpty {
            Section("设置") {
                ForEach(settings, id: \.id) { setting in
                    SettingRowMac(
                        setting: setting,
                        value: binding(for: setting)
                    )
                }
            }
        } else {
            Section("设置") {
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
}
