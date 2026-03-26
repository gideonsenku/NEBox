//
//  CheckBoxGroup.swift
//  NEBox
//
//  Created by Senku on 9/10/24.
//

import SwiftUI

struct CheckBoxGroup: View {
    let items: [RadioItem]  // 使用 CheckBoxItem 结构体数组
    @Binding var selectedKeys: [String]  // 绑定选中的 keys

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.key) { item in
                CheckBox(id: item.key, label: item.label, isSelected: self.isSelected(item.key)) {
                    self.toggleSelection(for: item.key)
                }
            }
        }
    }

    // 判断当前 key 是否在选中项中
    private func isSelected(_ key: String) -> Bool {
        selectedKeys.contains(key)
    }

    // 切换选中状态
    private func toggleSelection(for key: String) {
        if let index = selectedKeys.firstIndex(of: key) {
            selectedKeys.remove(at: index)  // 如果已经选中，则取消选中
        } else {
            selectedKeys.append(key)  // 如果未选中，则添加到选中项
        }
    }
}

struct CheckBox: View {
    let id: String
    let label: String
    let isSelected: Bool
    let callback: () -> Void
    let size: CGFloat = 20
    let color: Color = Color.primary
    let textSize: CGFloat = 16

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.size, height: self.size)
            
            Text(label)
                .font(Font.system(size: textSize))
                .foregroundColor(.black)
            Spacer()
        }
        .foregroundColor(isSelected ? .blue : color)
        .onTapGesture {
            self.callback() // 切换选中状态
        }
    }
}


struct CheckBoxGroupPrview: View {
    @State private var selectedOptions: [String] = []  // 选中的 keys

    var body: some View {
        VStack {
            Text("Selected options: \(selectedOptions.joined(separator: ", "))")

            // 定义 CheckBoxItem 数组
            let items = [
                RadioItem(key: "key1", label: "Option 1"),
                RadioItem(key: "key2", label: "Option 2"),
                RadioItem(key: "key3", label: "Option 3")
            ]

            // 将 items 和 selectedOptions 传递给 CheckBoxGroup
            CheckBoxGroup(items: items, selectedKeys: $selectedOptions)

            Button(action: {
                print("Selected options: \(selectedOptions)")
            }) {
                Text("Submit")
            }
        }
        .padding()
    }
}

#Preview {
    CheckBoxGroupPrview()
}

