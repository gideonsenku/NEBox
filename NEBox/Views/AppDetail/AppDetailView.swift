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

    var body: some View {
        HStack(spacing: 12) {
            if let iconUrl = app.icon, let url = URL(string: iconUrl) {
                WebImage(url: url)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 17, weight: .semibold))
                Text(app.author)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                if let repo = app.repo, !repo.isEmpty {
                    Text(repo)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width - 60, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

struct AppDescCardView: View {
    let app: AppModel?
    let width = UIScreen.main.bounds.width
    
    var body: some View {
        if app?.hasDescription == true {
            VStack(alignment: .leading, spacing: 2) {
                if let desc = app?.desc {
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(width: width - 60, alignment: .leading)
                }
                if let descs = app?.descs {
                    ForEach(descs, id: \.self) { desc in
                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(width: width - 60, alignment: .leading)
                    }
                }
                if let html = app?.desc_html {
                    HTMLTextView(html: html)
                        .frame(width: width - 60, alignment: .leading)
                }
                if let descs_html = app?.descs_html {
                    let html = descs_html.joined(separator: "<br>")
                    HTMLTextView(html: html)
                        .frame(width: width - 60, alignment: .leading)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
        if scripts.isEmpty != true {
            VStack(alignment: .leading) {
                Text("应用脚本(\(scripts.count))")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                VStack(spacing: 16) {
                    ForEach(Array(scripts.enumerated()), id: \.element.script) { index, script in
                        HStack {
                            Text("\(index + 1). \(script.name)")
                                .font(.system(size: 13))
                                .fontWeight(.medium)
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
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 60, alignment: .leading)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}


struct AppSettingsView: View {
    @Binding var settings: [Setting]
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    
    @State var selectedOption = "Paris"
    
    // 动态绑定到 settings 数组中的特定 val 值
    private func binding(for index: Int) -> Binding<String> {
        return Binding<String>(
            get: {
                if let stringValue = settings[index].val?.value as? String {
                    return stringValue
                } else {
                    return "" // 默认返回空字符串
                }
            },
            set: { newValue in
                settings[index].val = AnyCodable(newValue)
            }
        )
    }
    
    // 动态绑定到 Boolean 值
    private func boolBinding(for index: Int) -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                if let boolValue = settings[index].val?.value as? Bool {
                    return boolValue
                } else {
                    return false // 默认返回 false
                }
            },
            set: { newValue in
                settings[index].val = AnyCodable(newValue)
            }
        )
    }
    
    // 动态绑定到 Double 值
    private func doubleBinding(for index: Int) -> Binding<Double> {
        return Binding<Double>(
            get: {
                if let val = settings[index].val?.value {
                    if let d = val as? Double { return d }
                    if let n = val as? Int { return Double(n) }
                    if let s = val as? String, let d = Double(s) { return d }
                }
                return 0
            },
            set: { newValue in
                settings[index].val = AnyCodable(newValue)
            }
        )
    }

    // 动态绑定到 Color 值
    private func colorBinding(for index: Int) -> Binding<Color> {
        return Binding<Color>(
            get: {
                if let hex = settings[index].val?.value as? String, !hex.isEmpty {
                    return Color(hex: hex)
                }
                return .blue
            },
            set: { newValue in
                settings[index].val = AnyCodable(newValue.toHex())
            }
        )
    }

    // 动态绑定到 [String] 值
    private func arrayBinding(for index: Int) -> Binding<[String]> {
        return Binding<[String]>(
            get: {
                if let arrayValue = settings[index].val?.value as? [String] {
                    return arrayValue
                } else {
                    return [] // 默认返回空数组
                }
            },
            set: { newValue in
                settings[index].val = AnyCodable(newValue)
            }
        )
    }

    // 选择器绑定：保证返回值始终存在于 tag 列表中，避免 Picker invalid selection 警告
    private func pickerBinding(for index: Int, items: [RadioItem]) -> Binding<String> {
        return Binding<String>(
            get: {
                let current = (settings[index].val?.value as? String) ?? ""
                if items.contains(where: { $0.key == current }) {
                    return current
                }
                return items.first?.key ?? ""
            },
            set: { newValue in
                settings[index].val = AnyCodable(newValue)
            }
        )
    }

    // TODO: 需要拆分到子页面中
    var body: some View {
        @State var selectedFruit = "Apple"

        if settings.isEmpty != true {
            VStack(alignment: .leading) {
                Text("应用设置(\(settings.count))")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(settings.enumerated()), id: \.element.id) { index, setting in
                        switch setting.type {
                        case "boolean":
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(setting.name ?? "")
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                    Spacer()
                                    Toggle("", isOn: boolBinding(for: index))
                                        .labelsHidden()
                                }
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "textarea":
                            VStack(alignment: .leading, spacing: 2) {
                                Text(setting.name ?? "")
                                    .font(.system(size: 14))
                                    .lineLimit(1)

                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: binding(for: index))
                                        .padding(4)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                                        )
                                        .frame(height: 138)
                                    if setting.val == "" {
                                        Text(setting.name ?? "请输入内容...")
                                            .foregroundColor(.gray)
                                            .padding(.top, 12)
                                            .padding(.leading, 8)
                                    }
                                }
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "radios":
                            VStack(alignment: .leading, spacing: 2) {
                                Text(setting.name ?? "")
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                                
                                RadioButtonGroup(items: (setting.items ?? [] as [RadioItem]), selectedKey: binding(for: index))
                                    .padding(.top, 4)

                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "checkboxes":
                            VStack(alignment: .leading, spacing: 2) {
                                Text(setting.name ?? "")
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                                
                                CheckBoxGroup(items: (setting.items ?? []), selectedKeys: arrayBinding(for: index))
                                    .padding(.top, 4)

                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "selects", "modalSelects":
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(setting.name ?? "")
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    let pickerItems = setting.items ?? []
                                    if pickerItems.isEmpty {
                                        Text("-")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Picker("Select", selection: pickerBinding(for: index, items: pickerItems)) {
                                            ForEach(pickerItems) { item in
                                                Text(item.label).tag(item.key)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                    }
                                }
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "slider":
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(setting.name ?? "")
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                    Spacer()
                                    Text(String(format: "%.0f", doubleBinding(for: index).wrappedValue))
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: doubleBinding(for: index), in: 0...100, step: 1)
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "colorpicker":
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(setting.name ?? "")
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                    Spacer()
                                    ColorPicker("", selection: colorBinding(for: index))
                                        .labelsHidden()
                                }
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        case "number":
                            VStack(alignment: .leading, spacing: 2) {
                                Text(setting.name ?? "")
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                                TextField(setting.placeholder ?? "请输入数字", text: binding(for: index))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        default:
                            VStack(alignment: .leading, spacing: 2) {
                                Text(setting.name ?? "")
                                    .font(.system(size: 14))
                                    .lineLimit(1)

                                TextField(setting.placeholder ?? "请输入内容", text: binding(for: index))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                if let desc = setting.desc, desc != "" {
                                    Text(desc)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                            }
                        }
                    }
                    
                    Divider()
                    HStack {
                        Spacer()
                        
                        Button {
                            Task {
                                let params = settings.map { setting in
                                    let transformedVal: AnyCodable = {
                                        if setting.type == "checkboxes", let arrayVal = setting.val?.value as? [String] {
                                            return AnyCodable(arrayVal.joined(separator: ","))  // 将数组转换为字符串并封装为 AnyCodable
                                        } else if let val = setting.val {
                                            return val
                                        } else {
                                            return AnyCodable(nil)  // 如果 val 是 nil，返回 AnyCodable(nil)
                                        }
                                    }()
                                    return SessionData(key: setting.id, val: transformedVal)
                                }
                                await boxModel.saveData(params: params)
                                toastManager.showToast(message: "保存成功!")
                            }
                        } label: {
                            Text("保存")
                                .font(.system(size: 12))
                        }

                    }
                }

            }
            .frame(width: UIScreen.main.bounds.width - 60, alignment: .leading)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .onAppear(perform: {
//                print(settings)
            })
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

    var body: some View {
        if let app = app {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // App header
                        AppHeaderView(app: app)

                        AppDescCardView(app: app)
                        AppScriptsView(scripts: app.scripts ?? []) { resp in
                            scriptResult = resp
                            showScriptResult = true
                        }
                        AppSettingsView(settings: bindingForSettings())

                        // Session data section
                        if app.keys != nil && !cachedAppDataInfo.datas.isEmpty {
                            appSessionDataCard(app: app)
                        }

                        // Session list
                        ForEach(Array(cachedAppDataInfo.sessions.enumerated()), id: \.element.id) { index, session in
                            sessionCard(session: session, index: index, app: app)
                        }
                    }
                    .padding(.bottom, 84)
                    .navigationTitle(app.name)
                }
            }
            .overlay(alignment: .bottom) {
                appBottomActionBar(app: app)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
            .frame(width: UIScreen.main.bounds.width)
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

    // MARK: - Current Session Data Card

    private func appSessionDataCard(app: AppModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("当前会话")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                if let curSession = cachedAppDataInfo.curSession {
                    Text(curSession.name)
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                }
                Spacer()

                UIMenuButton(
                    systemImage: "ellipsis",
                    menu: UIMenu(children: [
                              UIMenu(options: .displayInline, children: [
                                    UIAction(title: "清除数据", image: UIImage(systemName: "trash"), attributes: .destructive) { [self] _ in
                                        Task {
                                            await boxModel.clearAppDatas(app: app)
                                            toastManager.showToast(message: "已清除")
                                        }
                                    }
                        ]),
                        UIAction(title: "复制", image: UIImage(systemName: "doc.on.doc")) { [self] _ in
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .prettyPrinted
                            if let data = try? encoder.encode(app),
                               let str = String(data: data, encoding: .utf8) {
                                copyToClipboard(text: str)
                                toastManager.showToast(message: "已复制")
                            }
                        },
                        UIAction(title: "导入", image: UIImage(systemName: "square.and.arrow.down")) { [self] _ in
                            showImportSession = true
                        },
                        UIAction(title: "复制数据", image: UIImage(systemName: "doc.on.clipboard")) { [self] _ in
                            copyAppDatas()
                        }
                    ])
                )
                .fixedSize(horizontal: true, vertical: true)
            }

            ForEach(cachedAppDataInfo.datas, id: \.key) { data in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.key)
                            .font(.system(size: 13, weight: .medium))
                        Text(dataValString(data.val) .isEmpty ? "无数据" : dataValString(data.val))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button {
                        Task {
                            await boxModel.clearAppDatas(app: app, key: data.key)
                            toastManager.showToast(message: "已清除")
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider()

            HStack {
                Spacer()
                Button {
                    Task {
                        await boxModel.saveAppSession(app: app, datas: cachedAppDataInfo.datas)
                        toastManager.showToast(message: "已克隆会话")
                    }
                } label: {
                    Text("克隆")
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width - 60, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Session Card

    private func sessionCard(session: Session, index: Int, app: AppModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let isCurrent = cachedAppDataInfo.curSession?.id == session.id
                Text("#\(index + 1) \(session.name)")
                    .font(.system(size: 14, weight: isCurrent ? .bold : .regular))
                    .foregroundColor(isCurrent ? .accentColor : .primary)
                Spacer()

                Menu {
                    Button(role: .destructive) {
                        Task {
                            await boxModel.delAppSession(sessionId: session.id)
                            toastManager.showToast(message: "已删除")
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }

            ForEach(session.datas, id: \.key) { data in
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.key)
                        .font(.system(size: 13, weight: .medium))
                    Text(dataValString(data.val).isEmpty ? "无数据" : dataValString(data.val))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 1)
            }

            Divider()

            HStack {
                Text(session.createTime.prefix(19).replacingOccurrences(of: "T", with: " "))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    Task {
                        await boxModel.useAppSession(sessionId: session.id, appId: app.id)
                        toastManager.showToast(message: "已使用")
                    }
                } label: {
                    Text("使用")
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                }
                Button {
                    Task {
                        await boxModel.linkAppSession(sessionId: session.id, appId: app.id)
                        toastManager.showToast(message: "已关联")
                    }
                } label: {
                    Text("关联")
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width - 80, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.leading, 20)
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
                        performImportSession()
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
                        Text(importSessionText.prefix(500) + (importSessionText.count > 500 ? "..." : ""))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(10)
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
        Task {
            await boxModel.impAppDatas(jsonString: importSessionText)
            toastManager.showToast(message: "导入成功!")
            showImportSession = false
            importSessionText = ""
        }
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
                    tintColor: UIColor(Color(hex: "#0F1729")),
                    menu: UIMenu(children: [
                        UIAction(title: "导入会话", image: UIImage(systemName: "square.and.arrow.down")) { [self] _ in
                            showImportSession = true
                        },
                        UIAction(title: "复制数据", image: UIImage(systemName: "doc.on.clipboard")) { [self] _ in
                            copyAppDatas()
                        },
                        UIAction(title: "清除数据", image: UIImage(systemName: "trash"), attributes: .destructive) { [self] _ in
                            Task {
                                await boxModel.clearAppDatas(app: app)
                                toastManager.showToast(message: "已清除")
                            }
                        }
                    ])
                )
                .frame(width: 48, height: 48)
                .background(
                    Color(hex: "#ECEEF4"),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task {
                        guard !isSavingSettings else { return }
                        await MainActor.run { isSavingSettings = true }
                        await saveCurrentAppSettings(app: app)
                        await MainActor.run { isSavingSettings = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSavingSettings {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(hasRun ? Color(hex: "#0F1729") : .white)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text("保存")
                    }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .foregroundColor(hasRun ? Color(hex: "#0F1729") : .white)
                .background(
                    hasRun ? Color(hex: "#ECEEF4") : Color(hex: "#002FA7"),
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
                            if isRunningScript {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "play.circle.fill")
                            }
                            Text("运行")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .background(
                        Color(hex: "#002FA7"),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .shadow(color: Color(hex: "#002FA7").opacity(0.13), radius: 10, x: 0, y: 4)
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
                Color.white.opacity(0.8)
                Rectangle().fill(.ultraThinMaterial).opacity(0.35)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 0.5),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: -4)
    }

    // MARK: - Helpers

    private func saveCurrentAppSettings(app: AppModel) async {
        await boxModel.saveData(params: (app.settings ?? []).map { setting in
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
                if app != nil { app!.settings = newValue }
            }
        )
    }

    private func dataValString(_ val: AnyCodable?) -> String {
        guard let val = val else { return "" }
        if let str = val.value as? String { return str }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(val), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: val.value)
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
