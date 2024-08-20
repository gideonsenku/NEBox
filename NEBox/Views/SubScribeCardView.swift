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
    @EnvironmentObject var toastManager: ToastManager

    var item: AppSubCache
    var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HeaderView(item: item, isLoading: isLoading)
        }
        .padding()
        .background(Color.white)
        .onTapGesture {
            copyToClipboard(text: item.url ?? "")
            toastManager.showToast(message: "复制成功!")
        }
    }
}

struct HeaderView: View {
    var item: AppSubCache
    var isLoading: Bool  // 接收加载状态
    var body: some View {
        VStack {
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
                    HStack {
                        Text("\(item.name)(\(item.apps.count))")
                            .font(.system(size: 16))
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .frame(width: 12, height: 12)
                                .progressViewStyle(CircularProgressViewStyle())
                                .transition(.opacity)  // 使用透明度过渡而不是插入/移除
                        } else {
                            Text(item.updateTime.isEmpty ? "N/A" : item.formatTime)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    
                    Text(AttributedString("\(item.repo)"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(AttributedString("\(item.author)"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
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
