//
//  PreferencesView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI

/// Controls which icon variant (light / dark / auto) is shown for app icons within the app.
enum IconAppearance: String, CaseIterable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    /// Resolves to a concrete `isDark` value given the current system color scheme.
    func isDark(systemIsDark: Bool) -> Bool {
        switch self {
        case .auto: return systemIsDark
        case .light: return false
        case .dark: return true
        }
    }

    static let userDefaultsKey = "iconAppearance"
}

/// Controls the actual iOS home-screen app icon.
enum AppIconChoice: String, CaseIterable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    /// The image asset name used for preview in the picker.
    var previewImageName: String {
        switch self {
        case .auto: return "AppIcon-Light"
        case .light: return "AppIcon-Light"
        case .dark: return "AppIcon-Dark"
        }
    }

    /// The alternate icon name passed to `setAlternateIconName`. `nil` = default (auto light/dark).
    var alternateIconName: String? {
        switch self {
        case .auto: return nil
        case .light: return "AppIcon-LightOnly"
        case .dark: return "AppIcon-DarkOnly"
        }
    }

    static let userDefaultsKey = "appIconChoice"

    static var current: AppIconChoice {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let choice = AppIconChoice(rawValue: raw) else { return .auto }
        return choice
    }
}

struct PreferencesView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @AppStorage(IconAppearance.userDefaultsKey) private var iconAppearanceRaw: String = IconAppearance.auto.rawValue
    @AppStorage(AppIconChoice.userDefaultsKey) private var appIconChoiceRaw: String = AppIconChoice.auto.rawValue

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

    private var currentAppearance: IconAppearance {
        IconAppearance(rawValue: iconAppearanceRaw) ?? .auto
    }

    var body: some View {
        Form {
            Section(header: Text("通知")) {
                Toggle("勿扰模式", isOn: prefBoolBinding(\.isMute))
                Toggle("不显示查询警告", isOn: prefBoolBinding(\.isMuteQueryAlert))
            }

            Section(header: Text("外观")) {
                NavigationLink {
                    AppIconPickerView()
                } label: {
                    HStack {
                        Text("应用图标")
                        Spacer()
                        Text((AppIconChoice(rawValue: appIconChoiceRaw) ?? .auto).displayName)
                            .foregroundColor(.secondary)
                    }
                }
                NavigationLink {
                    IconAppearancePickerView()
                } label: {
                    HStack {
                        Text("图标风格")
                        Spacer()
                        Text(currentAppearance.displayName)
                            .foregroundColor(.secondary)
                    }
                }
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
                .modifier(ScrollDismissKeyboardModifier())
            }
        }
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

// MARK: - App Icon Picker

struct AppIconPickerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage(AppIconChoice.userDefaultsKey) private var selectedRaw: String = AppIconChoice.auto.rawValue

    private var selected: AppIconChoice {
        AppIconChoice(rawValue: selectedRaw) ?? .auto
    }

    private let iconSize: CGFloat = 62
    private var cornerRadius: CGFloat { iconSize * 0.2237 }

    var body: some View {
        Form {
            Section {
                ForEach(AppIconChoice.allCases, id: \.self) { choice in
                    Button {
                        selectedRaw = choice.rawValue
                        UIApplication.shared.setAlternateIconName(choice.alternateIconName)
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(choice.previewImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: iconSize, height: iconSize)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                            Text(choice.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if selected == choice {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("应用图标")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Icon Appearance Picker

struct IconAppearancePickerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage(IconAppearance.userDefaultsKey) private var iconAppearanceRaw: String = IconAppearance.auto.rawValue

    private var selected: IconAppearance {
        IconAppearance(rawValue: iconAppearanceRaw) ?? .auto
    }

    var body: some View {
        Form {
            Section {
                ForEach(IconAppearance.allCases, id: \.self) { style in
                    Button {
                        iconAppearanceRaw = style.rawValue
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack {
                            Text(style.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selected == style {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("图标")
        .navigationBarTitleDisplayMode(.inline)
    }
}
