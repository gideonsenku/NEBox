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

struct HTMLTextView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0 // Allow multiple lines
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = .clear
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        guard let data = html.data(using: .utf8) else {
            print("Failed to encode HTML string")
            return
        }
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
            uiView.attributedText = attributedString
            // Adjust the height of UILabel based on content
            let size = uiView.sizeThatFits(CGSize(width: uiView.frame.width, height: CGFloat.greatestFiniteMagnitude))
            uiView.frame.size.height = size.height
        } catch {
            print("Failed to parse HTML: \(error)")
        }
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
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct AppScriptsView: View {
    let scripts: [RunScript]
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
                            Button {
                                Task {
                                    let resp = try await ApiRequest.runScript(url: script.script)
                                }
                            } label: {
                                Image(systemName: "play.circle.fill")
                            }
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 60, alignment: .leading)
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}


struct AppSettingsView: View {
    @Binding var settings: [Setting]
    @EnvironmentObject var boxModel: BoxJsViewModel
    
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

    var body: some View {
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
                                        .scaleEffect(0.8)
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
                                        .background(Color.white)
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
                                await boxModel.saveData(params: settings.map { setting in
                                    SessionData(key: setting.id, val: setting.val)
                                })
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
            .background(Color.white)
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
    
    var body: some View {
        if let app = app {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        AppDescCardView(app: app)
                        AppScriptsView(scripts: app.scripts ?? [])
                        AppSettingsView(settings: bindingForSettings())
                    }
                    .padding(.bottom, 16)
                    .toolbar {
                        ToolbarItem {
                            HStack {
                                Button {
                                    Task {
                                        await boxModel.saveData(params: (app.settings ?? []).map { setting in
                                            SessionData(key: setting.id, val: setting.val)
                                        })
                                        toastManager.showToast(message: "保存成功!")
                                    }
                                } label: {
                                    Label("Run Script", systemImage: "externaldrive.fill.badge.checkmark")
                                }
                                
                                if let script = app.script {
                                    Button {
                                        Task {
                                            let resp = try await ApiRequest.runScript(url: script)
                                            print(resp)
                                        }
                                    } label: {
                                        Label("Run Script", systemImage: "play.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle(app.name)
                }
            }
            .frame(width: UIScreen.main.bounds.width)
            .background(
                BackgroundView(imageUrl: URL(string: boxModel.boxData.bgImgUrl))
            )
        }
    }
    
    // 创建一个处理 Optional settings 的绑定函数
    private func bindingForSettings() -> Binding<[Setting]> {
        return Binding<[Setting]>(
            get: {
                app?.settings ?? [] // 如果 app?.settings 是 nil，返回一个空数组
            },
            set: { newValue in
                if app != nil {
                    app!.settings = newValue // 如果 app 不为 nil，更新 settings
                }
            }
        )
    }
    
    private func presentSubscriptionAlert() {
        showTextFieldAlert(title: "添加订阅", message: nil, placeholder: "输入订阅地址", confirmButtonTitle: "确定", cancelButtonTitle: "取消") { inputText in
            Task {
                // await boxModel.addAppSub(url: inputText)
            }
        }
    }
}
