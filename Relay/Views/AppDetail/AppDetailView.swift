//
//  AppDetailView.swift
//  NEBox
//
//  Created by Senku on 8/27/24.
//

import SwiftUI
import UIKit
import WebKit
import AnyCodable
import SDWebImageSwiftUI
import UniformTypeIdentifiers

struct HTMLWebView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userController = WKUserContentController()
        userController.add(context.coordinator, name: "sizeNotify")
        config.userContentController = userController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let wrapped = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, sans-serif;
                font-size: 14px;
                line-height: 1.5;
                color: #666;
                background: transparent;
                word-wrap: break-word;
                overflow-wrap: break-word;
            }
            img { max-width: 100%; height: auto; }
            a { color: #007AFF; }
        </style>
        </head>
        <body>
        \(html)
        <script>
            function notifySize() {
                var h = document.body.scrollHeight;
                window.webkit.messageHandlers.sizeNotify.postMessage(h);
            }
            window.onload = notifySize;
            new MutationObserver(notifySize).observe(document.body, { childList: true, subtree: true });
            // fallback
            setTimeout(notifySize, 200);
            setTimeout(notifySize, 500);
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(wrapped, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var height: CGFloat

        init(height: Binding<CGFloat>) {
            _height = height
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "sizeNotify", let h = message.body as? CGFloat {
                DispatchQueue.main.async {
                    if h > 0 && h != self.height {
                        self.height = h
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

// MARK: - iOS 15 Compatibility

struct HideScrollContentBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content.onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
        }
    }
}

private struct GroupedFormStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.formStyle(.grouped)
        } else {
            content
        }
    }
}

// MARK: - UIMenu Button Wrapper

private final class NoHighlightMenuUIButton: UIButton {
    override var isHighlighted: Bool {
        get { false }
        set { }
    }
}

private struct UIMenuButton: UIViewRepresentable {
    let systemImage: String
    var tintColor: UIColor = .secondaryLabel
    var backgroundColor: UIColor = .clear
    var cornerRadius: CGFloat = 0
    let menu: UIMenu

    func makeUIView(context: Context) -> UIButton {
        let button = NoHighlightMenuUIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero
        configuration.baseBackgroundColor = backgroundColor
        configuration.background.backgroundColor = backgroundColor
        configuration.background.cornerRadius = cornerRadius
        configuration.background.strokeColor = .clear
        configuration.background.visualEffect = nil
        button.configuration = configuration
        button.showsMenuAsPrimaryAction = true
        button.adjustsImageWhenHighlighted = false
        button.backgroundColor = .clear
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = false
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.configurationUpdateHandler = { control in
            guard var cfg = control.configuration else { return }
            cfg.baseBackgroundColor = backgroundColor
            cfg.background.backgroundColor = backgroundColor
            cfg.background.cornerRadius = cornerRadius
            cfg.background.strokeColor = .clear
            cfg.background.visualEffect = nil
            control.configuration = cfg
        }
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: systemImage, withConfiguration: symbolConfig)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.tintColor = tintColor
        button.menu = menu
    }
}

struct HTMLTextView: View {
    let html: String
    @State private var webViewHeight: CGFloat = 1

    var body: some View {
        HTMLWebView(html: html, height: $webViewHeight)
            .frame(height: webViewHeight)
    }
}


struct AppHeaderView: View {
    let app: AppModel
    @Environment(\.openURL) private var openURL

    private var repoURL: URL? {
        guard let repo = app.repo, !repo.isEmpty else { return nil }
        return URL(string: repo)
    }

    var body: some View {
        HStack(spacing: 12) {
            AppIconView(app: app, size: 56)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 17, weight: .semibold))
                Text(app.author)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                if let repo = app.repo, !repo.isEmpty {
                    HStack(spacing: 3) {
                        if repoURL != nil {
                            Image(systemName: "link")
                                .font(.system(size: 9))
                        }
                        Text(repo)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(repoURL != nil ? .accent : .secondary)
                }
            }
            Spacer()
            if repoURL != nil {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = repoURL {
                openURL(url)
            }
        }
    }
}

struct AppDescCardView: View {
    let app: AppModel?

    var body: some View {
        if app?.hasDescription == true {
            VStack(alignment: .leading, spacing: 2) {
                if let desc = app?.desc {
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let descs = app?.descs {
                    ForEach(descs, id: \.self) { desc in
                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if let html = app?.desc_html {
                    HTMLTextView(html: html)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let descs_html = app?.descs_html {
                    let html = descs_html.joined(separator: "<br>")
                    HTMLTextView(html: html)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct AppScriptsView: View {
    let scripts: [RunScript]
    var onScriptResult: ((ScriptResp) -> Void)? = nil
    @State private var isLoading = false
    @State private var loadingScript: String? = nil
    @EnvironmentObject var boxModel: BoxJsViewModel

    var body: some View {
        if !scripts.isEmpty {
            ForEach(Array(scripts.enumerated()), id: \.element.script) { index, script in
                HStack {
                    Label {
                        Text(script.name)
                            .font(.system(size: 15))
                    } icon: {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.accentColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    Spacer()
                    if isLoading && loadingScript == script.script {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Button {
                            Task {
                                isLoading = true
                                loadingScript = script.script
                                do {
                                    let resp: ScriptResp = try await NetworkProvider.request(.runScript(url: script.script))
                                    onScriptResult?(resp)
                                    boxModel.fetchData()
                                } catch {
                                    onScriptResult?(ScriptResp(exception: "请求失败: \(error.localizedDescription)", output: nil))
                                }
                                isLoading = false
                                loadingScript = nil
                            }
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}


// MARK: - Form Setting Row

struct FormSettingRow: View {
    let setting: Setting
    let index: Int
    @Binding var settings: [Setting]

    private func binding(for index: Int) -> Binding<String> {
        Binding<String>(
            get: { (settings[index].val?.value as? String) ?? "" },
            set: { settings[index].val = AnyCodable($0) }
        )
    }

    private func boolBinding(for index: Int) -> Binding<Bool> {
        Binding<Bool>(
            get: { (settings[index].val?.value as? Bool) ?? false },
            set: { settings[index].val = AnyCodable($0) }
        )
    }

    private func doubleBinding(for index: Int) -> Binding<Double> {
        Binding<Double>(
            get: {
                if let val = settings[index].val?.value {
                    if let d = val as? Double { return d }
                    if let n = val as? Int { return Double(n) }
                    if let s = val as? String, let d = Double(s) { return d }
                }
                return 0
            },
            set: { settings[index].val = AnyCodable($0) }
        )
    }

    private func colorBinding(for index: Int) -> Binding<Color> {
        Binding<Color>(
            get: {
                if let hex = settings[index].val?.value as? String, !hex.isEmpty {
                    return Color(hex: hex)
                }
                return .blue
            },
            set: { settings[index].val = AnyCodable($0.toHex()) }
        )
    }

    private func arrayBinding(for index: Int) -> Binding<[String]> {
        Binding<[String]>(
            get: { (settings[index].val?.value as? [String]) ?? [] },
            set: { settings[index].val = AnyCodable($0) }
        )
    }

    private func pickerBinding(for index: Int, items: [RadioItem]) -> Binding<String> {
        Binding<String>(
            get: {
                let current = (settings[index].val?.value as? String) ?? ""
                if items.contains(where: { $0.key == current }) { return current }
                return items.first?.key ?? ""
            },
            set: { settings[index].val = AnyCodable($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingControl
            if let desc = setting.desc, !desc.isEmpty {
                Text(desc)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var settingControl: some View {
        switch setting.type {
        case "boolean":
            Toggle(setting.name ?? "", isOn: boolBinding(for: index))
                .font(.body)

        case "textarea":
            VStack(alignment: .leading, spacing: 6) {
                Text(setting.name ?? "")
                    .font(.body)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: binding(for: index))
                        .font(.body)
                        .frame(minHeight: 100, maxHeight: 200)
                        .modifier(HideScrollContentBackground())
                        .padding(8)
                        .background(Color(.tertiarySystemFill))
                        .cornerRadius(10)
                    if (settings[index].val?.value as? String)?.isEmpty != false {
                        Text(setting.placeholder ?? "请输入内容...")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 16)
                            .padding(.leading, 13)
                            .allowsHitTesting(false)
                    }
                }
            }

        case "radios":
            VStack(alignment: .leading, spacing: 8) {
                Text(setting.name ?? "")
                    .font(.body)
                RadioButtonGroup(items: setting.items ?? [], selectedKey: binding(for: index))
            }

        case "checkboxes":
            VStack(alignment: .leading, spacing: 8) {
                Text(setting.name ?? "")
                    .font(.body)
                CheckBoxGroup(items: setting.items ?? [], selectedKeys: arrayBinding(for: index))
            }

        case "selects", "modalSelects":
            let pickerItems = setting.items ?? []
            HStack {
                Text(setting.name ?? "")
                    .font(.body)
                Spacer()
                if pickerItems.isEmpty {
                    Text("-")
                        .foregroundColor(.secondary)
                } else {
                    Picker("", selection: pickerBinding(for: index, items: pickerItems)) {
                        ForEach(pickerItems) { item in
                            Text(item.label).tag(item.key)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

        case "slider":
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(setting.name ?? "")
                        .font(.body)
                    Spacer()
                    Text(String(format: "%.0f", doubleBinding(for: index).wrappedValue))
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.accentColor)
                        .monospacedDigit()
                }
                Slider(value: doubleBinding(for: index), in: 0...100, step: 1)
                    .tint(.accentColor)
            }

        case "colorpicker":
            HStack {
                Text(setting.name ?? "")
                    .font(.body)
                Spacer()
                ColorPicker("", selection: colorBinding(for: index))
                    .labelsHidden()
            }

        case "number":
            VStack(alignment: .leading, spacing: 6) {
                Text(setting.name ?? "")
                    .font(.body)
                TextField(setting.placeholder ?? "请输入数字", text: binding(for: index))
                    .keyboardType(.decimalPad)
                    .font(.body)
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(10)
            }

        default:
            VStack(alignment: .leading, spacing: 6) {
                Text(setting.name ?? "")
                    .font(.body)
                TextField(setting.placeholder ?? "请输入内容", text: binding(for: index))
                    .font(.body)
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(10)
            }
        }
    }
}

struct AppSettingsView: View {
    @Binding var settings: [Setting]

    var body: some View {
        if !settings.isEmpty {
            ForEach(Array(settings.enumerated()), id: \.element.id) { index, setting in
                FormSettingRow(setting: setting, index: index, settings: $settings)
            }
        }
    }
}

struct AppDetailView: View {
    @State var app: AppModel?

    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var showImportSession = false
    @State private var importSessionText = ""
    @State private var showImportFilePickerSession = false
    @State private var showScriptResult = false
    @State private var scriptResult: ScriptResp? = nil
    @State private var cachedAppDataInfo = AppDataInfo(datas: [], sessions: [], curSession: nil)
    @State private var isSavingSettings = false
    @State private var isRunningScript = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        if let app = app {
            Form {
                // MARK: App Info
                Section {
                    AppHeaderView(app: app)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                if app.hasDescription {
                    Section {
                        AppDescCardView(app: app)
                    }
                }

                // MARK: Scripts
                if let scripts = app.scripts, !scripts.isEmpty {
                    Section {
                        AppScriptsView(scripts: scripts) { resp in
                            scriptResult = resp
                            showScriptResult = true
                        }
                    } header: {
                        Text("应用脚本")
                    }
                }

                // MARK: Settings
                let settings = app.settings ?? []
                if !settings.isEmpty {
                    Section {
                        AppSettingsView(settings: bindingForSettings())
                    } header: {
                        Text("应用设置")
                    }
                }

                // MARK: Session Data
                if app.keys != nil && !cachedAppDataInfo.datas.isEmpty {
                    appSessionDataSection(app: app)
                }

                // MARK: Sessions
                if !cachedAppDataInfo.sessions.isEmpty {
                    Section {
                        ForEach(Array(cachedAppDataInfo.sessions.enumerated()), id: \.element.id) { index, session in
                            sessionRow(session: session, index: index, app: app)
                        }
                    } header: {
                        Text("历史会话")
                    }
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
            .modifier(GroupedFormStyle())
            .navigationTitle(app.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        toggleFav(app)
                    } label: {
                        Image(systemName: isFavorite(app) ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite(app) ? .red : .secondary)
                            .font(.system(size: 17))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                appBottomActionBar(app: app)
                    .offset(y: keyboardHeight)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = frame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
            .neboxHideTabBar()
            .sheet(isPresented: $showImportSession) {
                importSessionSheet(app: app)
            }
            .sheet(isPresented: $showScriptResult) {
                scriptResultSheet
            }
            .onDisappear {
                Task {
                    await boxModel.flushPendingDataUpdates()
                }
            }
            .onAppear {
                refreshCachedAppDataInfo()
            }
            .onReceive(boxModel.$boxData) { _ in
                refreshCachedAppDataInfo()
            }
        }
    }

    // MARK: - Current Session Data Section

    private func appSessionDataSection(app: AppModel) -> some View {
        Section {
            ForEach(cachedAppDataInfo.datas, id: \.key) { data in
                let valStr = dataValString(data.val)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.key)
                            .font(.system(size: 14, weight: .medium))
                        Text(valStr.isEmpty ? "无数据" : valStr)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                    Button {
                        boxModel.clearAppDatas(app: app, key: data.key)
                        toastManager.showToast(message: "已清除")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    copyToClipboard(text: valStr)
                    toastManager.showToast(message: "已复制")
                }
            }

            Button {
                boxModel.saveAppSession(app: app, datas: cachedAppDataInfo.datas)
                toastManager.showToast(message: "已克隆会话")
            } label: {
                Label("克隆当前会话", systemImage: "doc.on.doc")
                    .font(.system(size: 14))
            }
        } header: {
            HStack {
                Text("当前会话")
                if let curSession = cachedAppDataInfo.curSession {
                    Text(curSession.name)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Session Row

    private func sessionRow(session: Session, index: Int, app: AppModel) -> some View {
        let isCurrent = cachedAppDataInfo.curSession?.id == session.id

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Text("#\(index + 1)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isCurrent ? Color.accentColor : Color(.tertiaryLabel), in: Capsule())
                    Text(session.name)
                        .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? .accentColor : .primary)
                }
                Spacer()
                UIMenuButton(
                    systemImage: "ellipsis",
                    tintColor: UIColor(.secondary),
                    menu: UIMenu(children: [
                        UIAction(title: "复制会话", image: UIImage(systemName: "doc.on.doc")) { [self] _ in
                            copySession(session)
                        },
                        UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { [self] _ in
                            boxModel.delAppSession(sessionId: session.id)
                            toastManager.showToast(message: "已删除")
                        }
                    ])
                )
                .frame(width: 24, height: 24)
            }

            if !session.datas.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(session.datas, id: \.key) { data in
                        let valStr = dataValString(data.val)
                        HStack(alignment: .top, spacing: 6) {
                            Text(data.key)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(valStr.isEmpty ? "无数据" : valStr)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 180, alignment: .trailing)
                        }
                    }
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(8)
            }

            HStack {
                Text(session.createTime.prefix(19).replacingOccurrences(of: "T", with: " "))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    boxModel.useAppSession(sessionId: session.id, appId: app.id)
                    toastManager.showToast(message: "已使用")
                } label: {
                    Text("使用")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                Button {
                    boxModel.linkAppSession(sessionId: session.id, appId: app.id)
                    toastManager.showToast(message: "已关联")
                } label: {
                    Text("关联")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Import Session Sheet

    private func importSessionSheet(app: AppModel) -> some View {
        neboxNavigationContainer {
            Form {
                Section(footer: Text("支持 JSON 格式的会话数据")) {
                    Button {
                        guard let str = UIPasteboard.general.string, !str.isEmpty else {
                            toastManager.showToast(message: "剪贴板为空")
                            return
                        }
                        importSessionText = str
                    } label: {
                        Label("从剪贴板粘贴", systemImage: "doc.on.clipboard")
                    }

                    Button {
                        showImportFilePickerSession = true
                    } label: {
                        Label("从文件导入", systemImage: "doc")
                    }
                }

                if !importSessionText.isEmpty {
                    Section(header: Text("数据预览")) {
                        ScrollView {
                            Text(importSessionText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .navigationTitle("导入会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showImportSession = false
                        importSessionText = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认导入") {
                        performImportSession()
                    }
                    .disabled(importSessionText.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showImportFilePickerSession,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let str = String(data: data, encoding: .utf8), !str.isEmpty {
                        importSessionText = str
                        performImportSession()
                    } else {
                        toastManager.showToast(message: "文件读取失败")
                    }
                }
            }
        }
    }

    private func performImportSession() {
        guard !importSessionText.isEmpty else { return }
        if boxModel.importSession(jsonString: importSessionText) {
            toastManager.showToast(message: "导入会话成功!")
        } else {
            toastManager.showToast(message: "会话数据格式错误")
        }
        showImportSession = false
        importSessionText = ""
    }

    // MARK: - Script Result Sheet

    private var scriptResultSheet: some View {
        ScriptResultSheetView(
            scriptResult: scriptResult,
            onClose: { showScriptResult = false }
        )
    }

    private func appBottomActionBar(app: AppModel) -> some View {
        let hasRun = app.script?.isEmpty == false

        return VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                UIMenuButton(
                    systemImage: "ellipsis",
                    tintColor: UIColor(.textPrimary),
                    menu: UIMenu(children: [
                        UIAction(title: "导入会话", image: UIImage(systemName: "square.and.arrow.down")) { [self] _ in
                            showImportSession = true
                        },
                        UIAction(title: "复制数据", image: UIImage(systemName: "doc.on.clipboard")) { [self] _ in
                            copyAppDatas()
                        },
                        UIAction(title: "复制会话", image: UIImage(systemName: "doc.on.doc")) { [self] _ in
                            if let session = cachedAppDataInfo.curSession {
                                copySession(session)
                            }
                        },
                        UIAction(title: "清除数据", image: UIImage(systemName: "trash"), attributes: .destructive) { [self] _ in
                            Task {
                                boxModel.clearAppDatas(app: app)
                                toastManager.showToast(message: "已清除")
                            }
                        }
                    ])
                )
                .frame(width: 48, height: 48)
                .background(
                    Color.bgMuted,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task { @MainActor in
                        guard !isSavingSettings else { return }
                        isSavingSettings = true
                        saveCurrentAppSettings(app: app)
                        isSavingSettings = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Group {
                            if isSavingSettings {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(hasRun ? .textPrimary : .white)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                        .frame(width: 20, height: 20)
                        Text("保存")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(hasRun ? .textPrimary : .white)
                .background(
                    hasRun ? Color.bgMuted : Color.accent,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .opacity(isSavingSettings ? 0.85 : 1)
                .disabled(isSavingSettings)
                .accessibilityLabel("保存")

                if let script = app.script, !script.isEmpty {
                    Button {
                        Task {
                            guard !isRunningScript else { return }
                            isRunningScript = true
                            await runAppScript(script)
                            isRunningScript = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Group {
                                if isRunningScript {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                            }
                            .frame(width: 20, height: 20)
                            Text("运行")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .background(
                        Color.accent,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .shadow(color: Color.accent.opacity(0.13), radius: 10, x: 0, y: 4)
                    .opacity(isRunningScript ? 0.85 : 1)
                    .disabled(isRunningScript)
                    .accessibilityLabel("运行")
                }

            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.bgCard.opacity(0.8)
                Rectangle().fill(.ultraThinMaterial).opacity(0.35)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.bgCard.opacity(0.25))
                .frame(height: 0.5),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: -4)
    }

    // MARK: - Helpers

    @MainActor
    private func saveCurrentAppSettings(app: AppModel) {
        boxModel.saveData(params: (app.settings ?? []).map { setting in
            let transformedVal: AnyCodable = {
                if setting.type == "checkboxes", let arrayVal = setting.val?.value as? [String] {
                    return AnyCodable(arrayVal.joined(separator: ","))
                } else if let val = setting.val {
                    return val
                } else {
                    return AnyCodable(nil)
                }
            }()
            return SessionData(key: setting.id, val: transformedVal)
        })
        toastManager.showToast(message: "保存成功!")
    }

    private func runAppScript(_ script: String) async {
        do {
            let resp: ScriptResp = try await NetworkProvider.request(.runScript(url: script))
            scriptResult = resp
            showScriptResult = true
            boxModel.fetchData()
        } catch {
            scriptResult = ScriptResp(exception: "请求失败: \(error.localizedDescription)", output: nil)
            showScriptResult = true
        }
    }

    private func refreshCachedAppDataInfo() {
        guard let app = app else {
            cachedAppDataInfo = AppDataInfo(datas: [], sessions: [], curSession: nil)
            return
        }
        cachedAppDataInfo = boxModel.boxData.loadAppDataInfo(for: app)
    }

    private func bindingForSettings() -> Binding<[Setting]> {
        return Binding<[Setting]>(
            get: { app?.settings ?? [] },
            set: { newValue in
                app?.settings = newValue
            }
        )
    }

    private static let jsonEncoder = JSONEncoder()

    private func dataValString(_ val: AnyCodable?) -> String {
        guard let val = val else { return "" }
        if let str = val.value as? String { return str }
        if let data = try? Self.jsonEncoder.encode(val), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: val.value)
    }

    private func isFavorite(_ app: AppModel) -> Bool {
        let favIds = boxModel.boxData.usercfgs?.favapps ?? []
        return favIds.contains(app.id)
    }

    private func toggleFav(_ app: AppModel) {
        var favIds = boxModel.boxData.usercfgs?.favapps ?? []
        if let idx = favIds.firstIndex(of: app.id) {
            favIds.remove(at: idx)
        } else {
            favIds.append(app.id)
        }
        boxModel.updateData(path: "usercfgs.favapps", data: favIds)
    }

    private func copySession(_ session: Session) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(session),
           let str = String(data: data, encoding: .utf8) {
            copyToClipboard(text: str)
            toastManager.showToast(message: "已复制会话")
        }
    }

    private func copyAppDatas() {
        var result: [String: String] = [:]
        for data in cachedAppDataInfo.datas {
            result[data.key] = dataValString(data.val)
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: result),
           let str = String(data: jsonData, encoding: .utf8) {
            copyToClipboard(text: str)
            toastManager.showToast(message: "已复制数据")
        }
    }

}
