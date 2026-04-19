//
//  MacPreferencesView.swift
//  RelayMac
//

import SwiftUI

struct MacPreferencesView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var boxModel: BoxJsViewModel

    @AppStorage(MacIconAppearance.userDefaultsKey) private var iconAppearanceRaw: String = MacIconAppearance.auto.rawValue
    @AppStorage("appThemePreference") private var themePreferenceRaw: String = ThemePreference.auto.rawValue
    @AppStorage("notify.script")  private var notifyScript: Bool  = true
    @AppStorage("notify.error")   private var notifyError: Bool   = true
    @AppStorage("notify.backup")  private var notifyBackup: Bool  = false

    @State private var editingURL: Bool = false
    @State private var draftURL: String = ""
    @State private var showResetConfirm: Bool = false
    @State private var httpapiDraft: String = ""
    @State private var pendingHttpapi: String?

    private var isConfigured: Bool { apiManager.isApiUrlSet() }
    private var isSurgeEnv: Bool { boxModel.boxData.syscfgs?.env == "Surge" }
    private var currentTheme: ThemePreference { ThemePreference(rawValue: themePreferenceRaw) ?? .auto }
    private var currentIconAppearance: MacIconAppearance { MacIconAppearance(rawValue: iconAppearanceRaw) ?? .auto }
    private var httpapiPickerItems: [String] {
        guard let raw = boxModel.boxData.usercfgs?.httpapis, !raw.isEmpty else { return [] }
        return raw.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("设置")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    connectionSection
                    appearanceSection
                    notificationsSection
                    if isConfigured {
                        boxjsSection
                    }
                    if isConfigured && isSurgeEnv {
                        surgeSection
                    }
                    aboutSection
                }
                .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onDisappear {
            commitHttpapiDraft()
            Task { await boxModel.flushPendingDataUpdates() }
        }
        .confirmationDialog(
            "重置连接？",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("重置", role: .destructive) {
                apiManager.apiUrl = nil
                toastManager.showToast(message: "已重置")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将断开当前 BoxJS 连接并清除已保存的服务器地址。")
        }
    }

    // MARK: - Sections

    private var connectionSection: some View {
        SettingsSection(title: "连接") {
            SettingsRow(
                title: "后端地址",
                subtitle: "BoxJS 后端服务器的 URL"
            ) {
                if editingURL {
                    HStack(spacing: 8) {
                        TextField(ApiManager.defaultAPIURL, text: $draftURL)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(minWidth: 220)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(SettingsPillBackground())
                        Button("保存") {
                            let trimmed = draftURL.trimmingCharacters(in: .whitespaces)
                            apiManager.apiUrl = trimmed.isEmpty ? nil : trimmed
                            toastManager.showToast(message: "地址已保存")
                            editingURL = false
                            if apiManager.isApiUrlSet() { boxModel.fetchData() }
                        }
                        .keyboardShortcut(.defaultAction)
                        Button("取消") {
                            draftURL = apiManager.apiUrl ?? ""
                            editingURL = false
                        }
                    }
                } else {
                    Button {
                        draftURL = apiManager.apiUrl ?? ""
                        editingURL = true
                    } label: {
                        Text(apiManager.apiUrl ?? "未配置")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(isConfigured ? .primary : .tertiary)
                            .frame(width: 240, alignment: .leading)
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(SettingsPillBackground())
                    }
                    .buttonStyle(.plain)
                    .help("点击编辑")
                }
            }

            SettingsDivider()

            SettingsRow(
                title: "连接状态",
                subtitle: "当前与 BoxJS 后端的连接"
            ) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConfigured ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(isConfigured ? "已连接" : "未配置")
                        .font(.system(size: 13))
                        .foregroundStyle(isConfigured ? Color.green : Color.orange)
                }
            }

            SettingsDivider()

            SettingsRow(
                title: "重置连接",
                subtitle: "断开并清除已保存的地址"
            ) {
                Button {
                    showResetConfirm = true
                } label: {
                    Text("重置")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.red.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isConfigured)
            }
        }
    }

    private var appearanceSection: some View {
        SettingsSection(title: "外观") {
            SettingsRow(
                title: "主题",
                subtitle: "选择浅色或深色外观"
            ) {
                SettingsMenuPicker(
                    label: currentTheme.displayName,
                    options: ThemePreference.allCases,
                    optionLabel: { $0.displayName }
                ) { newValue in
                    themePreferenceRaw = newValue.rawValue
                }
            }

            SettingsDivider()

            SettingsRow(
                title: "图标风格",
                subtitle: "侧栏和应用列表里图标的明暗风格"
            ) {
                SettingsMenuPicker(
                    label: currentIconAppearance.displayName,
                    options: MacIconAppearance.allCases,
                    optionLabel: { $0.displayName }
                ) { newValue in
                    iconAppearanceRaw = newValue.rawValue
                }
            }
        }
    }

    private var notificationsSection: some View {
        SettingsSection(title: "通知") {
            SettingsRow(
                title: "脚本完成通知",
                subtitle: "脚本运行结束时发送通知"
            ) {
                Toggle("", isOn: $notifyScript)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            SettingsDivider()

            SettingsRow(
                title: "错误提示",
                subtitle: "连接失败或脚本出错时弹出提示"
            ) {
                Toggle("", isOn: $notifyError)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            SettingsDivider()

            SettingsRow(
                title: "备份提醒",
                subtitle: "周期性提醒创建备份"
            ) {
                Toggle("", isOn: $notifyBackup)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }

    private var boxjsSection: some View {
        SettingsSection(title: "BoxJS 偏好") {
            boxjsToggle(title: "勿扰模式",       subtitle: "静默所有弹窗确认",        keyPath: \.isMute,           key: "isMute")
            SettingsDivider()
            boxjsToggle(title: "勿扰查询警告",   subtitle: "跳过查询时的确认提示",    keyPath: \.isMuteQueryAlert, key: "isMuteQueryAlert")
            SettingsDivider()
            boxjsToggle(title: "隐藏帮助",       subtitle: "在 BoxJS Web 界面中隐藏帮助", keyPath: \.isHideHelp,       key: "isHideHelp")
            SettingsDivider()
            boxjsToggle(title: "隐藏 Box 图标",   subtitle: "隐藏顶栏 Box 图标",         keyPath: \.isHideBoxIcon,    key: "isHideBoxIcon")
            SettingsDivider()
            boxjsToggle(title: "隐藏我的标题",   subtitle: "隐藏「我的」标题栏",      keyPath: \.isHideMyTitle,    key: "isHideMyTitle")
            SettingsDivider()
            boxjsToggle(title: "隐藏编码",       subtitle: "在 BoxJS 中隐藏编码入口",  keyPath: \.isHideCoding,     key: "isHideCoding")
            SettingsDivider()
            boxjsToggle(title: "隐藏刷新",       subtitle: "隐藏刷新按钮",            keyPath: \.isHideRefresh,    key: "isHideRefresh")
            SettingsDivider()
            boxjsToggle(title: "Web 调试",       subtitle: "开启 Web 调试模式",        keyPath: \.isDebugWeb,       key: "isDebugWeb")
        }
    }

    @ViewBuilder
    private func boxjsToggle(
        title: String,
        subtitle: String,
        keyPath: KeyPath<UserConfig, Bool?>,
        key: String
    ) -> some View {
        SettingsRow(title: title, subtitle: subtitle) {
            Toggle("", isOn: prefBinding(for: keyPath, key: key))
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    @ViewBuilder
    private var surgeSection: some View {
        SettingsSection(title: "Surge") {
            SettingsRow(
                title: "HTTP-API",
                subtitle: "Surge 的 HTTP API 地址"
            ) {
                if !httpapiPickerItems.isEmpty {
                    SettingsMenuPicker(
                        label: (boxModel.boxData.usercfgs?.httpapi?.isEmpty == false
                                ? boxModel.boxData.usercfgs?.httpapi
                                : nil) ?? "未设置",
                        options: [""] + httpapiPickerItems,
                        optionLabel: { $0.isEmpty ? "未设置" : $0 }
                    ) { newValue in
                        boxModel.updateData(path: "usercfgs.httpapi", data: newValue)
                        Task { await boxModel.flushPendingDataUpdates() }
                    }
                } else {
                    TextField("examplekey@127.0.0.1:6166", text: $httpapiDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(width: 260)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(SettingsPillBackground())
                        .onSubmit { commitHttpapiDraft() }
                        .onAppear {
                            httpapiDraft = boxModel.boxData.usercfgs?.httpapi ?? ""
                        }
                }
            }
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "关于") {
            SettingsRow(title: "版本", subtitle: "当前应用版本") {
                Text(appVersionString)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Binding helper

    private func prefBinding(
        for keyPath: KeyPath<UserConfig, Bool?>,
        key: String
    ) -> Binding<Bool> {
        Binding(
            get: { boxModel.boxData.usercfgs?[keyPath: keyPath] ?? false },
            set: { newValue in
                boxModel.updateData(path: "usercfgs.\(key)", data: newValue)
                Task { await boxModel.flushPendingDataUpdates() }
            }
        )
    }

    private func commitHttpapiDraft() {
        let value = httpapiDraft
        guard value != (boxModel.boxData.usercfgs?.httpapi ?? "") else { return }
        pendingHttpapi = value
        boxModel.updateData(path: "usercfgs.httpapi", data: value)
        Task {
            await boxModel.flushPendingDataUpdates()
            await MainActor.run {
                if pendingHttpapi == value { pendingHttpapi = nil }
            }
        }
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}

// MARK: - Theme preference

enum ThemePreference: String, CaseIterable, Hashable {
    case auto, light, dark

    var displayName: String {
        switch self {
        case .auto:  return "跟随系统"
        case .light: return "浅色"
        case .dark:  return "深色"
        }
    }
}

// MARK: - Settings section card

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 16)
            trailing()
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 1)
    }
}

private struct SettingsPillBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

private struct SettingsMenuPicker<Option: Hashable>: View {
    let label: String
    let options: [Option]
    let optionLabel: (Option) -> String
    let onSelect: (Option) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(optionLabel(option)) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .fixedSize()
        .background(SettingsPillBackground())
    }
}
