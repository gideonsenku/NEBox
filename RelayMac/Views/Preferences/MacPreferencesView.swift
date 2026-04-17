//
//  MacPreferencesView.swift
//  RelayMac
//

import SwiftUI

struct MacPreferencesView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var boxModel: BoxJsViewModel

    @State private var draftURL: String = ""
    @State private var editing: Bool = false

    private var isConfigured: Bool { apiManager.isApiUrlSet() }

    var body: some View {
        Form {
            serverSection
            preferencesSection
            actionsSection
            aboutSection
        }
        .formStyle(.grouped)
        .padding(10)
    }

    // MARK: - Sections

    private var serverSection: some View {
        Section("BoxJS 服务器") {
            if editing {
                TextField("", text: $draftURL, prompt: Text(ApiManager.defaultAPIURL))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                HStack {
                    Button("取消") {
                        draftURL = apiManager.apiUrl ?? ""
                        editing = false
                    }
                    Spacer()
                    Button("保存") {
                        let trimmed = draftURL.trimmingCharacters(in: .whitespaces)
                        apiManager.apiUrl = trimmed.isEmpty ? nil : trimmed
                        toastManager.showToast(message: "地址已保存")
                        editing = false
                        if apiManager.isApiUrlSet() {
                            boxModel.fetchData()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } else {
                LabeledContent("当前地址") {
                    Text(apiManager.apiUrl ?? "（未配置）")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(isConfigured ? .primary : .secondary)
                        .textSelection(.enabled)
                }
                Button("修改…") {
                    draftURL = apiManager.apiUrl ?? ""
                    editing = true
                }
            }
        }
    }

    @ViewBuilder
    private var preferencesSection: some View {
        Section {
            if !isConfigured {
                Text("请先配置 BoxJS 服务器")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Toggle("勿扰模式", isOn: prefBinding(for: \.isMute, key: "isMute"))
                Toggle("勿扰查询警告", isOn: prefBinding(for: \.isMuteQueryAlert, key: "isMuteQueryAlert"))
                Toggle("隐藏帮助", isOn: prefBinding(for: \.isHideHelp, key: "isHideHelp"))
                Toggle("隐藏 Box 图标", isOn: prefBinding(for: \.isHideBoxIcon, key: "isHideBoxIcon"))
                Toggle("隐藏我的标题", isOn: prefBinding(for: \.isHideMyTitle, key: "isHideMyTitle"))
                Toggle("隐藏编码", isOn: prefBinding(for: \.isHideCoding, key: "isHideCoding"))
                Toggle("隐藏刷新", isOn: prefBinding(for: \.isHideRefresh, key: "isHideRefresh"))
                Toggle("调试 Web", isOn: prefBinding(for: \.isDebugWeb, key: "isDebugWeb"))
            }
        } header: {
            Text("BoxJS 偏好")
        } footer: {
            if isConfigured {
                Text("修改会立即写回服务器")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        Section("操作") {
            Button("立即刷新数据") { boxModel.fetchData() }
                .disabled(!isConfigured)
            Button("清空服务器地址", role: .destructive) {
                apiManager.apiUrl = nil
                toastManager.showToast(message: "已清空")
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            LabeledContent("版本", value: appVersionString)
        }
    }

    // MARK: - Binding helper

    /// Reads `usercfgs.[field]` and writes `updateData(path: "usercfgs.<key>", data:)` on change.
    /// Triggers an async flush so the server actually receives the change — iOS relies on
    /// onDisappear-based flushes that don't naturally fire in a macOS single-window app.
    private func prefBinding(
        for keyPath: KeyPath<UserConfig, Bool?>,
        key: String
    ) -> Binding<Bool> {
        Binding(
            get: {
                boxModel.boxData.usercfgs?[keyPath: keyPath] ?? false
            },
            set: { newValue in
                boxModel.updateData(path: "usercfgs.\(key)", data: newValue)
                Task { await boxModel.flushPendingDataUpdates() }
            }
        )
    }

    // MARK: - Version

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
