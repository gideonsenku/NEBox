//
//  SwiftUIView.swift
//  NEBox
//
//  Created by Senku on 8/28/24.
//

import SwiftUI
import UIKit

struct HTMLTextView1: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.dataDetectorTypes = .all
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let data = html.data(using: .utf8) {
            let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
            uiView.attributedText = attributedString
        }
    }
}

struct ContentView1: View {
    var body: some View {
        HTMLTextView1(html: """
        因为接口失效，列表点赞功能移除，只有签到</br>⚠️使用说明</br>详情【<a href=\'https://github.com/lowking/Scripts/blob/master/QQVip/qqVipCheckIn.js?raw=true\'><font class=\'red--text\'>点我查看</font></a>】
        """)
//        .frame(height: 300) // Adjust the height as needed
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView1()
    }
}
