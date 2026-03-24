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

    var bgimgItems: [(name: String, url: String)] {
        guard let bgimgs = usercfgs?.bgimgs, !bgimgs.isEmpty else { return [] }
        return bgimgs.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: ",", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return (name: String(parts[0]), url: String(parts[1]))
        }
    }

    var body: some View {
        Form {
            Section(header: Text("外观")) {
                Picker("主题", selection: prefBinding(\.theme, default: "auto")) {
                    Text("自动").tag("auto")
                    Text("明亮").tag("light")
                    Text("暗黑").tag("dark")
                }

                if !bgimgItems.isEmpty {
                    Picker("背景图", selection: bgimgPickerBinding) {
                        Text("无").tag("")
                        ForEach(bgimgItems, id: \.url) { item in
                            Text(item.name).tag(item.url)
                        }
                    }
                }

                Toggle("透明图标", isOn: prefBoolBinding(\.isTransparentIcons))
                Toggle("壁纸模式", isOn: prefBoolBinding(\.isWallpaperMode))
            }

            Section(header: Text("通知")) {
                Toggle("勿扰模式", isOn: prefBoolBinding(\.isMute))
                Toggle("不显示查询警告", isOn: prefBoolBinding(\.isMuteQueryAlert))
            }

            Section(header: Text("界面")) {
                Toggle("隐藏帮助按钮", isOn: prefBoolBinding(\.isHideHelp))
                Toggle("隐藏悬浮按钮", isOn: prefBoolBinding(\.isHideBoxIcon))
                Toggle("隐藏我的标题", isOn: prefBoolBinding(\.isHideMyTitle))
                Toggle("隐藏编码按钮", isOn: prefBoolBinding(\.isHideCoding))
                Toggle("隐藏刷新按钮", isOn: prefBoolBinding(\.isHideRefresh))
            }

            Section(header: Text("调试")) {
                Toggle("调试模式", isOn: prefBoolBinding(\.isDebugWeb))
            }
        }
        .navigationTitle("偏好设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Background Image

    private var bgimgPickerBinding: Binding<String> {
        Binding<String>(
            get: { usercfgs?.bgimg ?? "" },
            set: { newValue in
                boxModel.updateData(path: "usercfgs.bgimg", data: newValue)
            }
        )
    }

    // MARK: - Binding Helpers

    private func prefBinding(_ keyPath: KeyPath<UserConfig, String?>, default defaultVal: String) -> Binding<String> {
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
            \UserConfig.theme: "usercfgs.theme",
            \UserConfig.bgimg: "usercfgs.bgimg",
            \UserConfig.isTransparentIcons: "usercfgs.isTransparentIcons",
            \UserConfig.isWallpaperMode: "usercfgs.isWallpaperMode",
            \UserConfig.isMute: "usercfgs.isMute",
            \UserConfig.isMuteQueryAlert: "usercfgs.isMuteQueryAlert",
            \UserConfig.isHideHelp: "usercfgs.isHideHelp",
            \UserConfig.isHideBoxIcon: "usercfgs.isHideBoxIcon",
            \UserConfig.isHideMyTitle: "usercfgs.isHideMyTitle",
            \UserConfig.isHideCoding: "usercfgs.isHideCoding",
            \UserConfig.isHideRefresh: "usercfgs.isHideRefresh",
            \UserConfig.isDebugWeb: "usercfgs.isDebugWeb",
        ]
        return map[keyPath] ?? "usercfgs.unknown"
    }
}
