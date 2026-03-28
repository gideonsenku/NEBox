//
//  ScriptEditorView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI

struct ScriptResultSheetView: View {
    let scriptResult: ScriptResp?
    let onClose: () -> Void

    var body: some View {
        neboxNavigationContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let resp = scriptResult {
                        Text((resp.exception?.isEmpty ?? true) ? "已完成" : "执行出错")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("脚本控制台")
                            .font(.headline)

                        Text("Log:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(resultText(resp))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor((resp.exception?.isEmpty ?? true) ? .primary : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    } else {
                        Text("无输出")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭", action: onClose)
                }
            }
        }
        .neboxSheetPresentation()
    }

    private func resultText(_ resp: ScriptResp) -> String {
        if let ex = resp.exception, !ex.isEmpty { return ex }
        if let out = resp.output, !out.isEmpty { return out }
        return "无输出"
    }
}

struct ScriptEditorView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var scriptText: String = """
/**
 * 注意:
 * 在这里你可以使用完整的 EnvJs 环境
 *
 * 同时:
 * 你`必须`手动调用 $done()
 *
 * 最后:
 * 这段脚本是可以直接运行的!
 */
const $ = new Env('Relay')
const host = $.getdata("boxjs_host")
console.log("输出的内容是返回给浏览器的!")
$.msg($.name, host)
$.done()
"""
    @State private var isRunning = false
    @State private var showResult = false
    @State private var scriptResult: ScriptResp? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $scriptText)
                .font(.system(size: 13, design: .monospaced))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(4)

            if scriptText.isEmpty {
                Text("输入脚本代码...")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
                    .padding(.leading, 9)
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("脚本编辑器")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResult, onDismiss: { scriptResult = nil }) {
            scriptConsoleSheet
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    runScript()
                } label: {
                    if isRunning {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .disabled(scriptText.isEmpty || isRunning)
            }
        }
    }

    private func runScript() {
        isRunning = true
        Task {
            do {
                let envMin = try await EnvScriptLoader.loadEnvMinScript()
                let scriptForRun = scriptText + "\n" + envMin
                let resp: ScriptResp = try await NetworkProvider.request(.runTxtScript(script: scriptForRun))
                await MainActor.run {
                    scriptResult = resp
                    isRunning = false
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    scriptResult = ScriptResp(exception: "请求失败: \(error.localizedDescription)", output: nil)
                    isRunning = false
                    showResult = true
                }
            }
        }
    }

    private var scriptConsoleSheet: some View {
        ScriptResultSheetView(
            scriptResult: scriptResult,
            onClose: { showResult = false }
        )
        }
}
