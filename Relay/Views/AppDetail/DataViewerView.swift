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
    @State private var hasQueried = false
    @FocusState private var isKeyFieldFocused: Bool
    @FocusState private var isEditorFocused: Bool

    var viewkeys: [String] {
        Array(Set(boxModel.boxData.usercfgs?.viewkeys ?? [])).filter { !$0.isEmpty }
    }

    var gistkeys: [String] {
        Array(Set(boxModel.boxData.usercfgs?.gist_cache_key ?? [])).filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Color.pageGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    queryCard

                    if !gistkeys.isEmpty {
                        chipSection(title: "非订阅数据", icon: "externaldrive", keys: gistkeys, removeType: "gist_cache_key")
                    }
                    if !viewkeys.isEmpty {
                        chipSection(title: "近期查看", icon: "clock", keys: viewkeys, removeType: "viewkeys")
                    }

                    resultCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            isKeyFieldFocused = false
            isEditorFocused = false
        })
        .navigationTitle("数据查看器")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Query Card

    private var queryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.textTertiary)

                    TextField("输入数据键, 如: boxjs_host", text: $queryKey)
                        .font(.system(size: 15))
                        .focused($isKeyFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { queryData() }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.bgMuted)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button {
                    queryData()
                } label: {
                    Group {
                        if isQuerying {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .background(queryKey.isEmpty ? Color.accent.opacity(0.4) : Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(queryKey.isEmpty || isQuerying)
            }

            if !queryKey.isEmpty {
                HStack(spacing: 12) {
                    Button {
                        copyToClipboard(text: queryKey)
                        toastManager.showToast(message: "已复制 Key")
                    } label: {
                        Label("复制 Key", systemImage: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.accent)
                    }

                    Spacer()

                    Button {
                        queryKey = ""
                        queryVal = ""
                        isValEditable = true
                        hasQueried = false
                    } label: {
                        Label("清除", systemImage: "xmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasQueried {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isValEditable ? Color.accent : Color.accentCoral)
                            .frame(width: 6, height: 6)
                        Text(isValEditable ? "可编辑" : "只读")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isValEditable ? .accent : .accentCoral)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isValEditable ? Color.accent : Color.accentCoral).opacity(0.1))
                    .clipShape(Capsule())

                    Spacer()

                    if !queryVal.isEmpty {
                        Button {
                            copyToClipboard(text: queryVal)
                            toastManager.showToast(message: "已复制数据")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 13))
                                .foregroundColor(.accent)
                        }
                    }
                }
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: isValEditable ? $queryVal : .constant(queryVal))
                    .font(.system(size: 13, design: .monospaced))
                    .focused($isEditorFocused)
                    .frame(minHeight: 120, maxHeight: 280)
                    .modifier(HideScrollContentBackground())
                    .padding(10)
                    .background(Color.bgMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .disabled(!isValEditable)

                if queryVal.isEmpty {
                    Text("数据内容")
                        .foregroundColor(.textTertiary)
                        .font(.system(size: 13))
                        .padding(.top, 18)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
            }

            if isValEditable && hasQueried {
                Button {
                    saveData()
                } label: {
                    HStack(spacing: 6) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13, weight: .medium))
                        }
                        Text("保存修改")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(.white)
                    .background(queryKey.isEmpty ? Color.accent.opacity(0.4) : Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(queryKey.isEmpty || isSaving)
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Chip Section

    private func chipSection(title: String, icon: String, keys: [String], removeType: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup {
                Group {
                    if #available(iOS 16.0, *) {
                        FlowLayout(spacing: 6) {
                            chipItems(keys: keys, removeType: removeType)
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)], alignment: .leading, spacing: 6) {
                            chipItems(keys: keys, removeType: removeType)
                        }
                    }
                }
                .padding(.top, 6)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.accent)
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                    Text("\(keys.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.bgMuted)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    @ViewBuilder
    private func chipItems(keys: [String], removeType: String) -> some View {
        ForEach(keys, id: \.self) { key in
            ChipView(label: key) {
                queryKey = key
                queryData()
            } onDelete: {
                removeKey(key, type: removeType)
            }
        }
    }

    // MARK: - Actions

    private func queryData() {
        guard !queryKey.isEmpty else { return }
        isQuerying = true
        isKeyFieldFocused = false
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
                    hasQueried = true
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

        // Optimistically update local state
        var newDatas = boxModel.boxData.datas
        newDatas[queryKey] = AnyCodable(queryVal)
        boxModel.boxData = boxModel.boxData.replacingDatas(newDatas)

        let key = queryKey, val = queryVal
        Task {
            do {
                let _: DataQueryResp = try await NetworkProvider.request(.saveDataKV(key: key, val: val))
                await MainActor.run {
                    isSaving = false
                    toastManager.showToast(message: "保存成功!")
                }
            } catch {
                // Refetch to restore consistent state
                await boxModel.fetchDataAsync()
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
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .onTapGesture { onTap() }

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.textInactive)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.bgMuted)
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

@available(iOS 16.0, *)
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
