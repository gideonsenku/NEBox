//
//  MacOnboardingSheet.swift
//  RelayMac
//

import SwiftUI

struct MacOnboardingSheet: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var boxModel: BoxJsViewModel

    @State private var inputURL: String = ""
    @State private var isValidating: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            Divider()
            form
            MacBoxJSInstallGuide()
            Spacer(minLength: 0)
            footer
        }
        .padding(32)
        .frame(width: 560)
        .frame(minHeight: 420)
        .background(.regularMaterial)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("欢迎使用 Relay")
                .font(.largeTitle).bold()
            Text("请输入 BoxJS 服务器地址以开始使用。Relay 支持 Loon / Surge / Shadowrocket / QuantumultX 等代理工具暴露的 BoxJS 接口。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("服务器地址")
                .font(.subheadline).bold()
            TextField("http://192.168.1.100:9090/box", text: $inputURL)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .disableAutocorrection(true)
                .onSubmit(save)

            if let err = errorMessage {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else {
                Text("可留空使用默认地址 \(ApiManager.defaultAPIURL)，也可以稍后在偏好设置里修改。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("使用默认地址") {
                inputURL = ApiManager.defaultAPIURL
                save()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                save()
            } label: {
                if isValidating {
                    ProgressView().controlSize(.small)
                } else {
                    Text("保存并继续")
                }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(inputURL.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
        }
    }

    private func save() {
        let trimmed = inputURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard URL(string: trimmed) != nil else {
            errorMessage = "地址格式不合法"
            return
        }
        errorMessage = nil
        isValidating = true
        apiManager.apiUrl = trimmed
        boxModel.fetchData()
        isValidating = false
    }
}
