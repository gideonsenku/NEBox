//
//  ScriptsSection.swift
//  RelayMac
//

import SwiftUI

struct ScriptsSection: View {
    let scripts: [RunScript]

    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var runningIndex: Int? = nil

    var body: some View {
        WorkbenchSectionBlock(title: "脚本") {
            VStack(spacing: 0) {
                ForEach(Array(scripts.enumerated()), id: \.offset) { pair in
                    let idx = pair.offset
                    let script = pair.element
                    HStack(spacing: 10) {
                        Text("\(idx + 1).")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(script.name).font(.body)
                            Text(script.script)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        Button {
                            run(script: script, at: idx)
                        } label: {
                            if runningIndex == idx {
                                ProgressView().controlSize(.small)
                            } else {
                                Label("运行", systemImage: "play.circle.fill")
                            }
                        }
                        .buttonStyle(.borderless)
                        .disabled(runningIndex != nil)
                    }
                    .padding(.vertical, 6)

                    if idx < scripts.count - 1 {
                        Divider()
                            .padding(.leading, 34)
                    }
                }
            }
        }
    }

    private func run(script: RunScript, at index: Int) {
        runningIndex = index
        toastManager.showLoading(message: "运行 \(script.name)…")
        let scriptURL = resolvedScriptURL(script.script)
        Task { @MainActor in
            defer {
                runningIndex = nil
                toastManager.hideLoading()
            }
            do {
                let resp: ScriptResp = try await NetworkProvider.request(.runScript(url: scriptURL))
                if let exception = resp.exception, !exception.isEmpty {
                    toastManager.showToast(message: "执行失败：\(exception)")
                } else {
                    toastManager.showToast(message: "\(script.name) 执行成功")
                }
                boxModel.fetchData()
            } catch {
                toastManager.showToast(message: "请求失败：\(error.localizedDescription)")
            }
        }
    }

    private func resolvedScriptURL(_ raw: String) -> String {
        guard URL(string: raw)?.scheme == nil else { return raw }
        let baseURL = ApiManager.shared.baseURL
        if raw.hasPrefix("/") {
            return "\(baseURL)\(raw)"
        }
        return "\(baseURL)/\(raw)"
    }
}
