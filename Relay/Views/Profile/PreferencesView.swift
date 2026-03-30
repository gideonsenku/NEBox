//
//  PreferencesView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    var usercfgs: UserConfig? { boxModel.boxData.usercfgs }

    private var isSurgeEnv: Bool {
        boxModel.boxData.syscfgs?.env == "Surge"
    }

    /// 与网页版一致：`httpapis` 为逗号分隔列表时使用选择器
    private var httpapiPickerItems: [String] {
        guard let raw = usercfgs?.httpapis, !raw.isEmpty else { return [] }
        return raw.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// 当前值若不在列表中，前置一项以免 Picker 无匹配
    private var httpapiPickerResolvedItems: [String] {
        let items = httpapiPickerItems
        guard let cur = usercfgs?.httpapi, !cur.isEmpty, !items.contains(cur) else { return items }
        return [cur] + items
    }

    var body: some View {
        Form {
            Section(header: Text("通知")) {
                Toggle("勿扰模式", isOn: prefBoolBinding(\.isMute))
                Toggle("不显示查询警告", isOn: prefBoolBinding(\.isMuteQueryAlert))
            }

            if isSurgeEnv {
                Section {
                    if !httpapiPickerItems.isEmpty {
                        Picker("HTTP-API (Surge)", selection: prefStringBinding(\.httpapi, default: "")) {
                            Text("未设置").tag("")
                            ForEach(httpapiPickerResolvedItems, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HTTP-API (Surge)")
                                .font(.subheadline)
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("examplekey@127.0.0.1:6166", text: prefStringBinding(\.httpapi, default: ""))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                if let v = usercfgs?.httpapi, !v.isEmpty, !isValidSurgeHttpApiFormat(v) {
                                    Text("格式错误，示例: examplekey@127.0.0.1:6166")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                } footer: {
                    if httpapiPickerItems.isEmpty {
                        Text("Surge http-api 地址，用于脚本与 Surge 交互。")
                    }
                }
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
        .navigationTitle("偏好设置")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            Task {
                await boxModel.flushPendingDataUpdates()
            }
        }
    }

    /// 与网页版校验一致：`.*?@.*?:[0-9]+`
    private func isValidSurgeHttpApiFormat(_ value: String) -> Bool {
        value.range(of: ".*?@.*?:[0-9]+", options: .regularExpression) != nil
    }

    // MARK: - Binding Helpers

    private func prefStringBinding(_ keyPath: KeyPath<UserConfig, String?>, default defaultVal: String) -> Binding<String> {
        let path = prefPath(for: keyPath)
        return Binding<String>(
            get: { usercfgs?[keyPath: keyPath] ?? defaultVal },
            set: { newValue in
                boxModel.updateData(path: path, data: newValue)
            }
        )
    }

    private func prefBoolBinding(_ keyPath: KeyPath<UserConfig, Bool?>) -> Binding<Bool> {
        let path = prefPath(for: keyPath)
        return Binding<Bool>(
            get: { usercfgs?[keyPath: keyPath] ?? false },
            set: { newValue in
                boxModel.updateData(path: path, data: newValue)
            }
        )
    }

    private func prefPath<T>(for keyPath: KeyPath<UserConfig, T>) -> String {
        let map: [PartialKeyPath<UserConfig>: String] = [
            \UserConfig.isMute: "usercfgs.isMute",
            \UserConfig.isMuteQueryAlert: "usercfgs.isMuteQueryAlert",
            \UserConfig.httpapi: "usercfgs.httpapi",
        ]
        return map[keyPath] ?? "usercfgs.unknown"
    }
}
