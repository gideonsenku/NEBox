//
//  DataViewerView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import AnyCodable

struct DataViewerView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var queryKey = ""
    @State private var queryVal = ""
    @State private var isValEditable = true
    @State private var isQuerying = false
    @State private var isSaving = false

    var viewkeys: [String] {
        Array(Set(boxModel.boxData.usercfgs?.viewkeys ?? [])).filter { !$0.isEmpty }
    }

    var gistkeys: [String] {
        Array(Set(boxModel.boxData.usercfgs?.gist_cache_key ?? [])).filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if !gistkeys.isEmpty {
                        collapsibleChipSection(title: "非订阅数据", keys: gistkeys, removeType: "gist_cache_key")
                    }
                    if !viewkeys.isEmpty {
                        collapsibleChipSection(title: "近期查看", keys: viewkeys, removeType: "viewkeys")
                    }
                    dataViewerCard
                    dataEditorCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("数据查看器")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Collapsible Chip Section

    private func collapsibleChipSection(title: String, keys: [String], removeType: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            DisclosureGroup {
                FlowLayout(spacing: 6) {
                    ForEach(keys, id: \.self) { key in
                        ChipView(label: key) {
                            queryKey = key
                            queryData()
                        } onDelete: {
                            removeKey(key, type: removeType)
                        }
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("\(title) (\(keys.count))")
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }

    // MARK: - Data Viewer Card

    private var dataViewerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("数据查看器")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    copyToClipboard(text: queryKey)
                    toastManager.showToast(message: "已复制 Key")
                } label: {
                    Text("复制")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
            }

            TextField("输入数据键, 如: boxjs_host", text: $queryKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 14))

            Text("输入要查询的数据键")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Divider()

            HStack {
                Spacer()
                Button {
                    queryData()
                } label: {
                    if isQuerying {
                        ProgressView()
                            .frame(width: 16, height: 16)
                    } else {
                        Text("查询")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                    }
                }
                .disabled(queryKey.isEmpty || isQuerying)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }

    // MARK: - Data Editor Card

    private var dataEditorCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("数据编辑器")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    copyToClipboard(text: queryVal)
                    toastManager.showToast(message: "已复制数据")
                } label: {
                    Text("复制")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: isValEditable ? $queryVal : .constant(queryVal))
                    .font(.system(size: 13))
                    .frame(minHeight: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .disabled(!isValEditable)

                if queryVal.isEmpty {
                    Text("数据内容")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                        .padding(.top, 12)
                        .padding(.leading, 8)
                        .allowsHitTesting(false)
                }
            }

            if !isValEditable {
                Text("该数据不可编辑")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Spacer()
                Button {
                    saveData()
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(width: 16, height: 16)
                    } else {
                        Text("保存")
                            .font(.system(size: 13))
                            .foregroundColor(isValEditable ? .accentColor : .secondary)
                    }
                }
                .disabled(!isValEditable || queryKey.isEmpty || isSaving)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }

    // MARK: - Actions

    private func queryData() {
        guard !queryKey.isEmpty else { return }
        isQuerying = true
        Task {
            do {
                let resp: DataQueryResp = try await NetworkProvider.request(.queryData(key: queryKey))
                await MainActor.run {
                    if let val = resp.val {
                        if let str = val.value as? String {
                            queryVal = str
                            isValEditable = true
                        } else {
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .prettyPrinted
                            if let data = try? encoder.encode(val),
                               let str = String(data: data, encoding: .utf8) {
                                queryVal = str
                            } else {
                                queryVal = String(describing: val.value)
                            }
                            isValEditable = false
                        }
                    } else {
                        queryVal = ""
                        isValEditable = true
                    }
                    isQuerying = false
                }
            } catch {
                await MainActor.run {
                    isQuerying = false
                    toastManager.showToast(message: "查询失败")
                }
            }
        }
    }

    private func saveData() {
        guard !queryKey.isEmpty, isValEditable else { return }
        isSaving = true
        Task {
            do {
                let _: DataQueryResp = try await NetworkProvider.request(.saveDataKV(key: queryKey, val: queryVal))
                await MainActor.run {
                    isSaving = false
                    toastManager.showToast(message: "保存成功!")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    toastManager.showToast(message: "保存失败")
                }
            }
        }
    }

    private func removeKey(_ key: String, type: String) {
        if type == "viewkeys" {
            var keys = boxModel.boxData.usercfgs?.viewkeys ?? []
            keys.removeAll { $0 == key }
            boxModel.updateData(path: "usercfgs.viewkeys", data: keys)
        } else {
            var keys = boxModel.boxData.usercfgs?.gist_cache_key ?? []
            keys.removeAll { $0 == key }
            boxModel.updateData(path: "usercfgs.gist_cache_key", data: keys)
        }
    }
}

// MARK: - Chip View

struct ChipView: View {
    let label: String
    var onTap: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .lineLimit(1)
                .onTapGesture { onTap() }

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
