//
//  MacScriptEditorView.swift
//  RelayMac
//

import SwiftUI

struct MacScriptEditorView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var scriptURL: String = ""
    @State private var scriptBody: String = "// 粘贴脚本内容或输入 URL 后加载\n"
    @State private var isLoadingURL: Bool = false
    @State private var isRunning: Bool = false
    @State private var scriptResult: ScriptResp?
    @State private var showResultInspector: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            Divider()
            TextEditor(text: $scriptBody)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(.background)
        }
        .navigationTitle("脚本编辑器")
        .inspector(isPresented: $showResultInspector) {
            if let scriptResult {
                MacScriptResultInspector(
                    scriptName: "临时脚本",
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
    }

    private var header: some View {
        HStack(spacing: 10) {
            TextField("脚本 URL (http://…/script.js)", text: $scriptURL)
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption, design: .monospaced))
                .onSubmit(loadScriptFromURL)
            Button {
                loadScriptFromURL()
            } label: {
                if isLoadingURL {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 44)
                } else {
                    Label("加载", systemImage: "arrow.down.circle")
                }
            }
            .disabled(!canLoadScriptURL)
            Button("清空") {
                scriptBody = ""
            }
            Button("复制") {
                PlatformBridge.copyToPasteboard(scriptBody)
                toastManager.showToast(message: "已复制")
            }
            .disabled(scriptBody.isEmpty)
            Button {
                runScript()
            } label: {
                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 44)
                } else {
                    Label("运行", systemImage: "play.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(scriptBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning || isLoadingURL)
        }
    }

    private var canLoadScriptURL: Bool {
        !scriptURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoadingURL && !isRunning
    }

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
                toastManager.showToast(message: "脚本已载入")
            } catch {
                toastManager.showToast(message: "加载失败：\(error.localizedDescription)")
            }
        }
    }

    private func runScript() {
        isRunning = true
        toastManager.showLoading(message: "执行脚本中…")
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
                showResultInspector = true
                if let exception = resp.exception, !exception.isEmpty {
                    toastManager.showToast(message: "执行失败：\(exception)")
                } else {
                    toastManager.showToast(message: "执行完成")
                }
            } catch {
                let resp = ScriptResp(exception: "请求失败：\(error.localizedDescription)", output: nil)
                scriptResult = resp
                showResultInspector = true
                toastManager.showToast(message: "请求失败：\(error.localizedDescription)")
            }
        }
    }
}
