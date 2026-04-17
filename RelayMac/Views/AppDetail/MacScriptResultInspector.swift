//
//  MacScriptResultInspector.swift
//  RelayMac
//

import SwiftUI

struct MacScriptResultInspector: View {
    let scriptName: String
    let result: ScriptResp
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            ScrollView {
                Text(outputText)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(isError ? .red : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(18)
        .navigationTitle("脚本结果")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("关闭", action: onClose)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scriptName)
                .font(.headline)
            Label(isError ? "执行失败" : "执行完成", systemImage: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isError ? .red : .green)
                .font(.subheadline)
        }
    }

    private var isError: Bool {
        !(result.exception?.isEmpty ?? true)
    }

    private var outputText: String {
        if let exception = result.exception, !exception.isEmpty {
            return exception
        }
        if let output = result.output, !output.isEmpty {
            return output
        }
        return "无输出"
    }
}
