//
//  SettingRowMac.swift
//  RelayMac
//

import AnyCodable
import SwiftUI

struct SettingRowMac: View {
    let setting: Setting
    @Binding var value: AnyCodable?

    var body: some View {
        switch setting.type {
        case "boolean", "checkbox":
            toggleRow
        case "radios", "radio":
            radioPicker
        case "select", "selects", "modalSelects":
            menuPickerRow
        default:
            textRow
        }
    }

    // MARK: - Rows

    private var toggleRow: some View {
        Toggle(isOn: boolBinding) {
            labelText
        }
    }

    private var textRow: some View {
        HStack {
            labelText
            Spacer()
            TextField(setting.placeholder ?? "", text: stringBinding)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)
        }
    }

    private var radioPicker: some View {
        let items: [RadioItem] = setting.items ?? []
        return Picker(selection: stringBinding) {
            ForEach(items) { item in
                Text(item.label).tag(item.key)
            }
        } label: {
            labelText
        }
    }

    private var menuPickerRow: some View {
        let items: [RadioItem] = setting.items ?? []
        let selectedKey = stringBinding.wrappedValue
        let selectedLabel = items.first(where: { $0.key == selectedKey })?.label ?? selectedKey

        return HStack {
            labelText
            Spacer()
            if items.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                Picker("", selection: stringBinding) {
                    ForEach(items) { item in
                        Text(item.label).tag(item.key)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 280, alignment: .trailing)
                .help(selectedLabel)
            }
        }
    }

    private var labelText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(setting.name ?? setting.id)
            if let desc = setting.desc, !desc.isEmpty {
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Bindings

    private var stringBinding: Binding<String> {
        Binding {
            guard let v = value?.value else { return "" }
            if let s = v as? String { return s }
            if let n = v as? NSNumber { return n.stringValue }
            return "\(v)"
        } set: { newValue in
            value = AnyCodable(newValue)
        }
    }

    private var boolBinding: Binding<Bool> {
        Binding {
            guard let v = value?.value else { return false }
            if let b = v as? Bool { return b }
            if let s = v as? String { return s == "true" || s == "1" }
            if let n = v as? NSNumber { return n.boolValue }
            return false
        } set: { newValue in
            value = AnyCodable(newValue)
        }
    }
}
