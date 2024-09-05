//
//  RadioGroups.swift
//  NEBox
//
//  Created by Senku on 9/5/24.
//

import SwiftUI

struct RadioButtonGroup: View {
    let items: [RadioItem]  // 使用 RadioItem 结构体数组
    @Binding var selectedKey: String  // 使用 key 来确定选中项

    var body: some View {
        VStack {
            ForEach(items, id: \.key) { item in  // 使用 key 作为唯一标识
                RadioButton(id: item.key, label: item.label, selectedID: $selectedKey)
            }
        }
    }
}

struct RadioButton: View {
    let id: String
    let label: String
    @Binding var selectedID: String  // 绑定到 RadioButtonGroup 的 selectedKey
    let size: CGFloat = 20
    let color: Color = Color.primary
    let textSize: CGFloat = 14

    var body: some View {
        Button(action: {
            self.selectedID = self.id  // 更新 selectedID 为当前按钮的 key
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: self.selectedID == self.id ? "largecircle.fill.circle" : "circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.size, height: self.size)
                Text(label)  // 显示 label 而不是 key
                    .font(Font.system(size: textSize))
                    .foregroundColor(.black)
                Spacer()
            }
            .foregroundColor(self.selectedID == self.id ? .blue : .gray)
        }
        .foregroundColor(self.color)
    }
}


