//
//  SubScribeCardView.swift
//  BoxJs
//
//  Created by Senku on 8/6/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Foundation

struct SubScribeCardView: View {
    var item: AppSubCache
    var isLoading: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HeaderView(item: item)
            ActionButtonsView(item: item, isLoading: isLoading)
        }
        .padding()
        .background(Color.white)
    }
}

struct HeaderView: View {
    var item: AppSubCache
    var body: some View {
        HStack {
            if let iconUrl = URL(string: item.icon) {
                WebImage(url: iconUrl) { image in
                    image.resizable()
                } placeholder: {
                    Rectangle().foregroundColor(.gray)
                }
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(item.name)")
                    .font(.headline)
                
                Text(AttributedString("\(item.repo)"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
            }
            
            Spacer()
            
            Text("\(item.apps.count)")
                .font(.headline)
                .foregroundColor(.red)
                .padding(8)
                .background(Circle().fill(Color.red.opacity(0.2)))
        }
        .padding(.bottom, 8)
    }
}

struct ActionButtonsView: View {
    var item: AppSubCache
    var isLoading: Bool  // 接收加载状态

    let buttons: [(imageName: String, color: Color)] = [
        ("doc.on.doc", .gray),
    ]
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(buttons, id: \.imageName) { button in
                ActionButton(imageName: button.imageName, color: button.color, text: item.url ?? "")
                    .padding(.horizontal, 4)
            }
            if isLoading {
                ProgressView()  // 显示加载指示器
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text(item.updateTime.isEmpty ? "N/A" : item.formatTime)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
    }
}

struct ActionButton: View {
    @EnvironmentObject var toastManager: ToastManager

    let imageName: String
    let color: Color
    let text: String
    
    var body: some View {
        Button(action: {
            if imageName == "doc.on.doc" {
                copyToClipboard(text: text)
                toastManager.showToast(message: "复制成功!")
            }
        }) {
            Image(systemName: imageName)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(color)
        }
    }
}

struct SubScribeCard_Previews: View {
    @State var isLoading = false
    @State var previewItem = AppSubCache(
        id: "1",
        name: "Senku应用订阅",
        icon: "https://avatars1.githubusercontent.com/u/39037656?s=460&u=5843b86eae433868b6ade4ec23f8353fe7300df4&v=4&quot",
        author: "Senku",
        repo: "https://github.com/gideonsenku",
        updateTime: "01-21",
        apps: [],
        isErr: false,
        enable: true,
        url: "https://github.com/gideonsenku",
        raw: nil
    )

    var body: some View {
        SubScribeCardView(item: previewItem, isLoading: isLoading)
    }
}

#Preview {
    SubScribeCard_Previews()
}
