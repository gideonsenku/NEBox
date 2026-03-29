//
//  CheckBoxGroup.swift
//  NEBox
//
//  Created by Senku on 9/10/24.
//

import SwiftUI

struct CheckBoxGroup: View {
    let items: [RadioItem]
    @Binding var selectedKeys: [String]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.key) { index, item in
                if index > 0 {
                    Divider()
                        .padding(.leading, 36)
                }
                CheckBox(
                    id: item.key,
                    label: item.label,
                    isSelected: selectedKeys.contains(item.key)
                ) {
                    toggleSelection(for: item.key)
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func toggleSelection(for key: String) {
        if let index = selectedKeys.firstIndex(of: key) {
            selectedKeys.remove(at: index)
        } else {
            selectedKeys.append(key)
        }
    }
}

struct CheckBox: View {
    let id: String
    let label: String
    let isSelected: Bool
    let callback: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .accentColor : Color(.tertiaryLabel))
                .animation(.easeInOut(duration: 0.15), value: isSelected)

            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            callback()
        }
    }
}

#Preview {
    struct CheckBoxGroupPreview: View {
        @State private var selectedOptions: [String] = []

        var body: some View {
            Form {
                Section("Checkboxes") {
                    CheckBoxGroup(
                        items: [
                            RadioItem(key: "key1", label: "Option 1"),
                            RadioItem(key: "key2", label: "Option 2"),
                            RadioItem(key: "key3", label: "Option 3")
                        ],
                        selectedKeys: $selectedOptions
                    )
                }
            }
        }
    }
    return CheckBoxGroupPreview()
}
