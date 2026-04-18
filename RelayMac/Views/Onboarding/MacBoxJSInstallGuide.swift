//
//  MacBoxJSInstallGuide.swift
//  RelayMac
//

import SwiftUI

struct MacBoxJSInstallGuide: View {
    @State private var isExpanded: Bool = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "puzzlepiece.extension")
                    Text("还没有安装 BoxJs 插件？")
                        .font(.subheadline).bold()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption).bold()
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("选择你正在使用的代理工具，一键安装 BoxJs 插件")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(MacProxyTool.allTools) { tool in
                            Button {
                                if let url = tool.buildSchemeURL() { openURL(url) }
                            } label: {
                                Text(tool.name)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }

                        Button {
                            if let url = URL(string: "https://docs.boxjs.app") { openURL(url) }
                        } label: {
                            Label("查看文档", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct MacProxyTool: Identifiable {
    let id = UUID()
    let name: String
    let pluginURL: String
    let schemeFormat: SchemeFormat

    enum SchemeFormat {
        case standard(scheme: String, action: String, param: String)
        case quantumultX
    }

    func buildSchemeURL() -> URL? {
        guard let encodedPlugin = pluginURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        switch schemeFormat {
        case .standard(let scheme, let action, let param):
            return URL(string: "\(scheme)://\(action)?\(param)=\(encodedPlugin)")
        case .quantumultX:
            let resource = "{\"rewrite_remote\":[\"\(pluginURL), tag=BoxJS\"]}"
            guard let encodedResource = resource.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return URL(string: "quantumult-x://add-resource?remote-resource=\(encodedResource)")
        }
    }

    static let allTools: [MacProxyTool] = [
        MacProxyTool(
            name: "Loon",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.loon.plugin",
            schemeFormat: .standard(scheme: "loon", action: "import", param: "plugin")
        ),
        MacProxyTool(
            name: "Surge",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.surge.sgmodule",
            schemeFormat: .standard(scheme: "surge", action: "/install-module", param: "url")
        ),
        MacProxyTool(
            name: "Shadowrocket",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.surge.sgmodule",
            schemeFormat: .standard(scheme: "shadowrocket", action: "install", param: "module")
        ),
        MacProxyTool(
            name: "Quantumult X",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.quanx.conf",
            schemeFormat: .quantumultX
        ),
        MacProxyTool(
            name: "Stash",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.stash.stoverride",
            schemeFormat: .standard(scheme: "stash", action: "install-override", param: "url")
        )
    ]
}
