//
//  BoxJSInstallGuideView.swift
//  Relay
//
//  Created by Senku on 3/31/26.
//

import SwiftUI

struct BoxJSInstallGuideView: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 12))
                    Text("还没有安装 BoxJs 插件？")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    Text("选择你正在使用的代理工具，一键安装 BoxJs 插件")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(ProxyTool.allTools) { tool in
                            Button {
                                openInstallURL(for: tool)
                            } label: {
                                Text(tool.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.tertiarySystemFill))
                                    .cornerRadius(8)
                                    .foregroundColor(.primary)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            if let url = URL(string: "https://docs.boxjs.app") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "safari")
                                    .font(.system(size: 12))
                                Text("查看文档")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(8)
                            .foregroundColor(.secondary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func openInstallURL(for tool: ProxyTool) {
        guard let installURL = tool.buildSchemeURL() else { return }
        UIApplication.shared.open(installURL)
    }
}

// MARK: - Proxy Tool Model

private struct ProxyTool: Identifiable {
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

    static let allTools: [ProxyTool] = [
        ProxyTool(
            name: "Loon",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.loon.plugin",
            schemeFormat: .standard(scheme: "loon", action: "import", param: "plugin")
        ),
        ProxyTool(
            name: "Surge",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.surge.sgmodule",
            schemeFormat: .standard(scheme: "surge", action: "/install-module", param: "url")
        ),
        ProxyTool(
            name: "Shadowrocket",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.surge.sgmodule",
            schemeFormat: .standard(scheme: "shadowrocket", action: "install", param: "module")
        ),
        ProxyTool(
            name: "Quantumult X",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.quanx.conf",
            schemeFormat: .quantumultX
        ),
        ProxyTool(
            name: "Stash",
            pluginURL: "https://github.com/chavyleung/scripts/raw/master/box/rewrite/boxjs.rewrite.stash.stoverride",
            schemeFormat: .standard(scheme: "stash", action: "install-override", param: "url")
        )
    ]
}
