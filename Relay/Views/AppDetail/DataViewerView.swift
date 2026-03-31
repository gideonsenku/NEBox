//
//  DataViewerView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import AnyCodable

// MARK: - Data Key Item

private struct DataKeyItem: Identifiable {
    let id: String
    let key: String
    let valuePreview: String
    let apps: [AppModel]
}

// MARK: - Data Viewer View

struct DataViewerView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var queryKey = ""
    @State private var debouncedQuery = ""
    @State private var queryVal = ""
    @State private var isValEditable = true
    @State private var isQuerying = false
    @State private var isSaving = false
    @State private var hasQueried = false
    @State private var selectedKey: String?
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var cachedKeyToAppsMap: [String: [AppModel]] = [:]
    @FocusState private var isKeyFieldFocused: Bool
    @FocusState private var isEditorFocused: Bool

    var viewkeys: [String] {
        // Preserve original order, deduplicate while keeping first occurrence
        var seen = Set<String>()
        return (boxModel.boxData.usercfgs?.viewkeys ?? []).filter { key in
            !key.isEmpty && seen.insert(key).inserted
        }
    }

    var gistkeys: [String] {
        var seen = Set<String>()
        return (boxModel.boxData.usercfgs?.gist_cache_key ?? []).filter { key in
            !key.isEmpty && seen.insert(key).inserted
        }
    }

    // MARK: - Reverse Index Builder

    private func buildKeyToAppsMap() -> [String: [AppModel]] {
        var map: [String: Set<String>] = [:]
        var appById: [String: AppModel] = [:]

        func index(_ app: AppModel) {
            appById[app.id] = app
            let allKeys = (app.keys ?? []) + (app.settings ?? []).map(\.id)
            for key in allKeys {
                map[key, default: []].insert(app.id)
            }
        }

        for sub in boxModel.boxData.appSubCaches.values {
            for app in sub.apps { index(app) }
        }
        for app in boxModel.boxData.sysapps { index(app) }

        return map.mapValues { ids in ids.compactMap { appById[$0] } }
    }

    // MARK: - Fuzzy Filtered Keys

    private var filteredKeys: [DataKeyItem] {
        let search = debouncedQuery.lowercased().trimmingCharacters(in: .whitespaces)
        guard !search.isEmpty else { return [] }

        let allKeys = Array(boxModel.boxData.datas.keys)
        let matched = allKeys.filter { $0.lowercased().contains(search) }

        let sorted = matched.sorted { a, b in
            let aPrefix = a.lowercased().hasPrefix(search)
            let bPrefix = b.lowercased().hasPrefix(search)
            if aPrefix != bPrefix { return aPrefix }
            return a < b
        }

        return sorted.prefix(50).map { key in
            DataKeyItem(
                id: key,
                key: key,
                valuePreview: dataPreview(boxModel.boxData.datas[key] ?? nil),
                apps: cachedKeyToAppsMap[key] ?? []
            )
        }
    }

    private var isSearching: Bool {
        !debouncedQuery.trimmingCharacters(in: .whitespaces).isEmpty && selectedKey == nil
    }

    // MARK: - Body

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
                    searchBar

                    if isSearching {
                        searchResultsList
                    } else {
                        if !gistkeys.isEmpty {
                            chipSection(title: "非订阅数据", icon: "externaldrive", keys: gistkeys, removeType: "gist_cache_key")
                        }
                        if !viewkeys.isEmpty {
                            chipSection(title: "近期查看", icon: "clock", keys: viewkeys, removeType: "viewkeys")
                        }
                    }

                    if hasQueried {
                        resultCard
                    }
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
        .onAppear {
            cachedKeyToAppsMap = buildKeyToAppsMap()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.textTertiary)

                    TextField("搜索数据键...", text: $queryKey)
                        .font(.system(size: 15))
                        .focused($isKeyFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            let key = queryKey.trimmingCharacters(in: .whitespaces)
                            guard !key.isEmpty else { return }
                            selectKey(key)
                        }
                        .onChange(of: queryKey) { newValue in
                            // When user is typing (not selecting from results), clear detail
                            if selectedKey != nil && newValue != selectedKey {
                                selectedKey = nil
                                hasQueried = false
                                queryVal = ""
                            }

                            // Debounce search
                            searchDebounceTask?.cancel()
                            searchDebounceTask = Task {
                                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    debouncedQuery = newValue
                                }
                            }
                        }

                    if !queryKey.isEmpty {
                        Button {
                            clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.bgMuted)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if selectedKey != nil && !queryKey.isEmpty {
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
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            let items = filteredKeys
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.textTertiary)
                    Text("没有找到匹配的键")
                        .font(.system(size: 14))
                        .foregroundColor(.textTertiary)

                    Button {
                        selectKey(queryKey.trimmingCharacters(in: .whitespaces))
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 13))
                            Text("直接查询 \"\(queryKey.trimmingCharacters(in: .whitespaces))\"")
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                HStack {
                    Text("搜索结果")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(items.count) 项")
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                ForEach(items) { item in
                    Button {
                        selectKey(item.key)
                    } label: {
                        DataKeyRow(item: item, isSelected: selectedKey == item.key)
                    }
                    .buttonStyle(.plain)

                    if item.id != items.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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

                if let key = selectedKey {
                    Text(key)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

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

            if isValEditable {
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
                    .background(selectedKey == nil ? Color.accent.opacity(0.4) : Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(selectedKey == nil || isSaving)
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
                .frame(maxWidth: .infinity, alignment: .leading)
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
                selectKey(key)
            } onDelete: {
                removeKey(key, type: removeType)
            }
        }
    }

    // MARK: - Actions

    private func clearSearch() {
        searchDebounceTask?.cancel()
        queryKey = ""
        debouncedQuery = ""
        queryVal = ""
        isValEditable = true
        hasQueried = false
        selectedKey = nil
    }

    private func selectKey(_ key: String) {
        searchDebounceTask?.cancel()
        selectedKey = key
        queryKey = key
        debouncedQuery = key
        isKeyFieldFocused = false
        addToViewkeys(key)
        queryData(key: key)
    }

    private func addToViewkeys(_ key: String) {
        var keys = boxModel.boxData.usercfgs?.viewkeys ?? []
        keys.removeAll { $0 == key }
        keys.insert(key, at: 0)
        boxModel.updateData(path: "usercfgs.viewkeys", data: keys)
    }

    private func queryData(key: String) {
        guard !key.isEmpty else { return }
        isQuerying = true
        Task {
            do {
                let resp: DataQueryResp = try await NetworkProvider.request(.queryData(key: key))
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
        guard let key = selectedKey, !key.isEmpty, isValEditable else { return }
        isSaving = true

        var newDatas = boxModel.boxData.datas
        newDatas[key] = AnyCodable(queryVal)
        boxModel.boxData = boxModel.boxData.replacingDatas(newDatas)

        let val = queryVal
        Task {
            do {
                let _: DataQueryResp = try await NetworkProvider.request(.saveDataKV(key: key, val: val))
                await MainActor.run {
                    isSaving = false
                    toastManager.showToast(message: "保存成功!")
                }
            } catch {
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

    // MARK: - Helpers

    private func dataPreview(_ val: AnyCodable?) -> String {
        guard let val = val else { return "null" }
        if let str = val.value as? String {
            return str
        }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(val),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: val.value)
    }
}

// MARK: - Data Key Row

private struct DataKeyRow: View {
    let item: DataKeyItem
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(item.key)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if !item.apps.isEmpty {
                    ForEach(item.apps.prefix(2)) { app in
                        Text(app.name)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(appTagColor(app.name).opacity(0.15))
                            .foregroundColor(appTagColor(app.name))
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }
                    if item.apps.count > 2 {
                        Text("+\(item.apps.count - 2)")
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                    }
                } else {
                    Text("未关联")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.textTertiary.opacity(0.15))
                        .foregroundColor(.textTertiary)
                        .clipShape(Capsule())
                }
            }

            if !item.valuePreview.isEmpty {
                Text(item.valuePreview)
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accent.opacity(0.06) : Color.clear)
    }

    /// Stable hash-based color — deterministic across app launches (unlike hashValue).
    private func appTagColor(_ name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .pink, .green, .cyan, .indigo, .mint]
        var hash: UInt32 = 5381
        for char in name.unicodeScalars {
            hash = hash &* 33 &+ char.value
        }
        return colors[Int(hash) % colors.count]
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
