//
//  RadioGroups.swift
//  NEBox
//
//  Created by Senku on 9/5/24.
//

import SwiftUI

struct RadioButtonGroup: View {
    let items: [RadioItem]
    @Binding var selectedKey: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.key) { index, item in
                if index > 0 {
                    Divider()
                        .padding(.leading, 36)
                }
                RadioButton(id: item.key, label: item.label, selectedID: $selectedKey)
                    .padding(.vertical, 10)
            }
        }
    }
}

struct RadioButton: View {
    let id: String
    let label: String
    @Binding var selectedID: String

    private var isSelected: Bool { selectedID == id }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Color.accentColor : Color(.tertiaryLabel), lineWidth: isSelected ? 2 : 1.5)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)

            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedID = id
        }
    }
}
