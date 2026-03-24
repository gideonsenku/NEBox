//
//  ScriptEditorView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI

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
const host = $.getdata("boxjs_host")
console.log("输出的内容是返回给浏览器的!")
$.msg($.name, host)
$.done()
"""
    @State private var isRunning = false
    @State private var showResult = false
    @State private var scriptResult: ScriptResp? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Code editor area
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

            Divider()

            // Result area
            if let resp = scriptResult {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("执行结果")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            scriptResult = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }

                    ScrollView {
                        Text(resultText(resp))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(resp.exception != nil ? .red : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(12)
                .background(Color(.systemGray6))
            }
        }
        .navigationTitle("脚本编辑器")
        .navigationBarTitleDisplayMode(.inline)
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
                let resp = try await ApiRequest.runTxtScript(script: scriptText)
                await MainActor.run {
                    scriptResult = resp
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    scriptResult = ScriptResp(exception: "请求失败: \(error.localizedDescription)", output: nil)
                    isRunning = false
                }
            }
        }
    }

    private func resultText(_ resp: ScriptResp) -> String {
        if let ex = resp.exception, !ex.isEmpty { return ex }
        if let out = resp.output, !out.isEmpty { return out }
        return "无输出"
    }
}
