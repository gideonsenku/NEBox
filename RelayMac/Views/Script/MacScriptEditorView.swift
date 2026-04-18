//
//  MacScriptEditorView.swift
//  RelayMac
//

import SwiftUI

struct MacScriptEditorView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var chrome: WindowChromeModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var scriptURL: String = ""
    @State private var scriptBody: String = "// BoxJS Script\nconst $ = new Env('My Script');\n\n!(async () => {\n  const data = $.getdata('key');\n  $.log(JSON.stringify(data));\n  $.done({ body: data });\n})();\n"
    @State private var isLoadingURL: Bool = false
    @State private var isRunning: Bool = false
    @State private var scriptResult: ScriptResp?
    @State private var showResultInspector: Bool = false
    @State private var showLoadURLPopover: Bool = false
    @State private var consoleLines: [ConsoleLine] = []
    @State private var showClearScriptConfirm: Bool = false

    private static let consoleLineCap: Int = 200

    var body: some View {
        VStack(spacing: 12) {
            header
            editorCard
            consoleCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .inspector(isPresented: $showResultInspector) {
            if let scriptResult {
                MacScriptResultInspector(
                    scriptName: displayedFilename,
                    result: scriptResult,
                    onClose: { showResultInspector = false }
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
        .onAppear { chrome.clear() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("脚本工坊")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 16)

            overflowMenu

            newButton

            runButton
        }
    }

    private var overflowMenu: some View {
        Menu {
            Button {
                showLoadURLPopover = true
            } label: {
                Label("从 URL 加载…", systemImage: "link")
            }
            Button {
                PlatformBridge.copyToPasteboard(scriptBody)
                toastManager.showToast(message: "已复制脚本")
            } label: {
                Label("复制脚本", systemImage: "doc.on.doc")
            }
            .disabled(scriptBody.isEmpty)
            if let scriptResult {
                Divider()
                Button {
                    showResultInspector = true
                } label: {
                    Label("查看结果", systemImage: "rectangle.righthalf.inset.filled.arrow.right")
                }
                .disabled(scriptResult.output?.isEmpty != false && (scriptResult.exception ?? "").isEmpty)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
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
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .popover(isPresented: $showLoadURLPopover, arrowEdge: .bottom) {
            loadURLPopover
        }
    }

    private var newButton: some View {
        Button {
            showClearScriptConfirm = true
        } label: {
            Image(systemName: "doc.badge.plus")
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
        .help("新建脚本")
        .confirmationDialog(
            "清空当前脚本？",
            isPresented: $showClearScriptConfirm,
            titleVisibility: .visible
        ) {
            Button("清空", role: .destructive) {
                scriptBody = ""
                scriptURL = ""
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("当前编辑器中的内容将被清空，无法恢复。")
        }
    }

    private var runButton: some View {
        Button(action: runScript) {
            Group {
                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.green)
            )
            .shadow(color: Color.green.opacity(0.25), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(scriptBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning || isLoadingURL)
        .help(isRunning ? "运行中…" : "运行脚本")
    }

    private var loadURLPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("从 URL 加载脚本")
                .font(.system(size: 13, weight: .semibold))
            TextField("http(s)://…/script.js", text: $scriptURL)
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption, design: .monospaced))
                .frame(minWidth: 320)
                .onSubmit { loadScriptFromURL(); showLoadURLPopover = false }
            HStack {
                Spacer()
                Button("取消") { showLoadURLPopover = false }
                Button {
                    loadScriptFromURL()
                    showLoadURLPopover = false
                } label: {
                    if isLoadingURL {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("加载")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canLoadScriptURL)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    // MARK: - Editor Card

    private var editorCard: some View {
        VStack(spacing: 0) {
            tabsRow
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
            MacJavaScriptCodeEditor(text: $scriptBody)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tabsRow: some View {
        HStack(alignment: .bottom, spacing: 4) {
            EditorTab(
                filename: displayedFilename,
                isActive: true,
                onClose: scriptBody.isEmpty ? nil : { showClearScriptConfirm = true }
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Console Card

    private var consoleCard: some View {
        VStack(spacing: 0) {
            consoleHeader
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
            consoleBody
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(height: 190)
    }

    private var consoleHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("控制台输出")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                showResultInspector = true
            } label: {
                consoleHeaderChip(icon: "rectangle.righthalf.inset.filled.arrow.right",
                                  title: "查看详情")
            }
            .buttonStyle(.plain)
            .disabled(scriptResult == nil)
            .opacity(scriptResult == nil ? 0.5 : 1)

            Button(action: clearConsole) {
                consoleHeaderChip(icon: "trash", title: "清空")
            }
            .buttonStyle(.plain)
            .disabled(consoleLines.isEmpty)
            .opacity(consoleLines.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func consoleHeaderChip(icon: String, title: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(title)
                .font(.system(size: 11))
        }
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    @ViewBuilder
    private var consoleBody: some View {
        ZStack {
            Color.primary.opacity(0.06)
            if consoleLines.isEmpty {
                emptyConsolePlaceholder
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(consoleLines) { line in
                                ConsoleRow(line: line)
                                    .id(line.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: consoleLines.count) { _, _ in
                        if let last = consoleLines.last {
                            withAnimation(.easeOut(duration: 0.15)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyConsolePlaceholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "terminal")
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text("点击「运行」执行脚本，输出将在这里显示")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Derived

    private var displayedFilename: String {
        let trimmed = scriptURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty,
           let url = URL(string: trimmed),
           !url.lastPathComponent.isEmpty,
           url.lastPathComponent != "/" {
            return url.lastPathComponent
        }
        return "script.js"
    }

    private var canLoadScriptURL: Bool {
        !scriptURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoadingURL && !isRunning
    }

    // MARK: - Actions

    private func loadScriptFromURL() {
        let trimmed = scriptURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = URL(string: trimmed), let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            toastManager.showToast(message: "请输入有效的 http/https 脚本地址")
            return
        }

        isLoadingURL = true
        toastManager.showLoading(message: "加载脚本中…")
        Task { @MainActor in
            defer {
                isLoadingURL = false
                toastManager.hideLoading()
            }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    toastManager.showToast(message: "加载失败：服务器返回异常")
                    return
                }
                guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
                    toastManager.showToast(message: "加载失败：脚本内容为空或编码不支持")
                    return
                }
                scriptBody = content
                appendConsole(.init(level: .info, message: "已从 \(url.lastPathComponent) 加载脚本（\(content.utf8.count) 字节）"))
                toastManager.showToast(message: "脚本已载入")
            } catch {
                appendConsole(.init(level: .error, message: "加载失败：\(error.localizedDescription)"))
                toastManager.showToast(message: "加载失败：\(error.localizedDescription)")
            }
        }
    }

    private func runScript() {
        isRunning = true
        toastManager.showLoading(message: "执行脚本中…")
        appendConsole(.init(level: .info, message: "脚本开始执行"))
        Task { @MainActor in
            defer {
                isRunning = false
                toastManager.hideLoading()
            }
            do {
                let envMin = try await EnvScriptLoader.loadEnvMinScript()
                let scriptForRun = scriptBody + "\n" + envMin
                let resp: ScriptResp = try await NetworkProvider.request(.runTxtScript(script: scriptForRun))
                scriptResult = resp
                appendOutput(from: resp)
                if let exception = resp.exception, !exception.isEmpty {
                    toastManager.showToast(message: "执行失败：\(exception)")
                } else {
                    toastManager.showToast(message: "执行完成")
                }
            } catch {
                let resp = ScriptResp(exception: "请求失败：\(error.localizedDescription)", output: nil)
                scriptResult = resp
                appendConsole(.init(level: .error, message: "请求失败：\(error.localizedDescription)"))
                toastManager.showToast(message: "请求失败：\(error.localizedDescription)")
            }
        }
    }

    private func appendOutput(from resp: ScriptResp) {
        if let output = resp.output {
            for line in output.split(whereSeparator: { $0.isNewline }) {
                let text = String(line).trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    appendConsole(.init(level: .log, message: text))
                }
            }
        }
        if let exception = resp.exception, !exception.isEmpty {
            appendConsole(.init(level: .error, message: exception))
        } else {
            appendConsole(.init(level: .info, message: "脚本执行完成"))
        }
    }

    private func appendConsole(_ line: ConsoleLine) {
        consoleLines.append(line)
        if consoleLines.count > Self.consoleLineCap {
            consoleLines.removeFirst(consoleLines.count - Self.consoleLineCap)
        }
    }

    private func clearConsole() {
        consoleLines.removeAll()
    }

}

// MARK: - Editor Tab

private struct EditorTab: View {
    let filename: String
    let isActive: Bool
    var onClose: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isActive ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
            Text(filename)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? AnyShapeStyle(HierarchicalShapeStyle.primary) : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
            if isActive, let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("关闭脚本")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 10,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 10,
                style: .continuous
            )
            .fill(isActive ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear))
        )
        .overlay(
            Group {
                if isActive {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 10,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 10,
                        style: .continuous
                    )
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                }
            }
        )
    }
}

// MARK: - Console Models & Row

private struct ConsoleLine: Identifiable {
    enum Level {
        case info, log, error
    }

    let id = UUID()
    let timestamp: Date
    let level: Level
    let message: String

    init(level: Level, message: String, timestamp: Date = Date()) {
        self.level = level
        self.message = message
        self.timestamp = timestamp
    }

    var levelLabel: String {
        switch level {
        case .info:  return "INFO"
        case .log:   return "LOG"
        case .error: return "ERROR"
        }
    }

    var levelColor: Color {
        switch level {
        case .info:  return .green
        case .log:   return .blue
        case .error: return .red
        }
    }
}

private struct ConsoleRow: View {
    let line: ConsoleLine

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Self.formatter.string(from: line.timestamp))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
            Text(line.levelLabel)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(line.levelColor)
                .frame(width: 44, alignment: .leading)
            Text(line.message)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
