//
//  AppDetailView.swift
//  NEBox
//
//  Created by Senku on 8/27/24.
//

import SwiftUI
import UIKit
import WebKit

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
    let width: CGFloat
    
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
            .frame(width: width)
        }
    }
}

struct AppDetailView: View {
    let app: AppModel?
    
    @EnvironmentObject var boxModel: BoxJsViewModel
    
    var body: some View {
        if let app = app {
            ZStack {
                ScrollView {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        AppDescCardView(app: app, width: width)
                    }
                    .toolbar {
                        if let script = app.script {
                            ToolbarItem {
                                Button {
                                    presentSubscriptionAlert()
                                } label: {
                                    Label("Run Script", systemImage: "play.circle.fill")
                                }
                            }
                        }
                    }
                    .navigationTitle(app.name)
                }
            }
            .background(
                BackgroundView(imageUrl: URL(string: boxModel.boxData.bgImgUrl))
            )
        }
    }
    
    private func presentSubscriptionAlert() {
        showTextFieldAlert(title: "添加订阅", message: nil, placeholder: "输入订阅地址", confirmButtonTitle: "确定", cancelButtonTitle: "取消") { inputText in
            // Perform the async task here
            Task {
                // await boxModel.addAppSub(url: inputText)
            }
        }
    }
}
