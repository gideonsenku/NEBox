//
//  MacDataViewerView.swift
//  RelayMac
//

import AnyCodable
import SwiftUI

struct MacDataViewerView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var chrome: WindowChromeModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var queryKey: String = ""
    @State private var queryValue: String = ""
    @State private var selectedKey: String?
    @State private var isValueEditable: Bool = true
    @State private var isSaving: Bool = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            bodyCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { chrome.clear() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("数据查看器")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
            countBadge
            Spacer(minLength: 16)
            searchField
                .frame(width: 280)
        }
    }

    private var countBadge: some View {
        Text("\(totalKeyCount) 项")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            )
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            TextField("搜索 key…", text: $queryKey)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .focused($searchFocused)
                .onSubmit {
                    let trimmed = queryKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    selectKey(trimmed)
                }
            if !queryKey.isEmpty {
                Button {
                    queryKey = ""
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.94, green: 0.94, blue: 0.95).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Body Card

    private var bodyCard: some View {
        HStack(spacing: 0) {
            keyList
                .frame(width: 300)

            Rectangle()
                .fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                .frame(width: 1)

            detailPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(red: 0.91, green: 0.91, blue: 0.93), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Key List

    @ViewBuilder
    private var keyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !filteredKeys.isEmpty {
                    sectionHeader("搜索结果")
                    ForEach(filteredKeys, id: \.self) { key in
                        keyRow(key, source: .search)
                    }
                }
                if !recentKeys.isEmpty {
                    sectionHeader("近期")
                    ForEach(recentKeys, id: \.self) { key in
                        keyRow(key, source: .recent)
                    }
                }
                if !externalKeys.isEmpty {
                    sectionHeader("非订阅")
                    ForEach(externalKeys, id: \.self) { key in
                        keyRow(key, source: .external)
                    }
                }
                if recentKeys.isEmpty, externalKeys.isEmpty, filteredKeys.isEmpty {
                    emptyKeyListPlaceholder
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private enum KeySource { case recent, external, search }

    @ViewBuilder
    private func keyRow(_ key: String, source: KeySource) -> some View {
        let isSelected = selectedKey == key
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(rowSubtitle(for: key, source: source))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if source == .recent || source == .external {
                Button {
                    removeStoredKey(key, source: source)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .opacity(isSelected ? 1 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { selectKey(key) }
    }

    private var emptyKeyListPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text("暂无数据 key")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Detail Panel

    @ViewBuilder
    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailHeader
            codePanel
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var detailHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let selectedKey {
                    Text(selectedKey)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                } else {
                    Text("选择一个 key")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                metaLine
            }
            Spacer(minLength: 0)
            if selectedKey != nil {
                detailActionButtons
            }
        }
    }

    @ViewBuilder
    private var metaLine: some View {
        HStack(spacing: 12) {
            if let owner = ownerAppName {
                Text("App: \(owner)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if !valueTypeLabel.isEmpty {
                Text(valueTypeLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if !valueSizeLabel.isEmpty {
                Text(valueSizeLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var detailActionButtons: some View {
        HStack(spacing: 8) {
            Button {
                PlatformBridge.copyToPasteboard(queryValue)
                toastManager.showToast(message: "已复制值")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                    Text("复制")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(queryValue.isEmpty)

            Button(action: saveData) {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                            .frame(width: 13, height: 13)
                    } else {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(isSaving ? "保存中" : "保存")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor)
                )
                .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!isValueEditable || isSaving)
            .help(isValueEditable ? "保存修改到 BoxJS" : "结构化数据为只读")
        }
    }

    @ViewBuilder
    private var codePanel: some View {
        ZStack(alignment: .topLeading) {
            if selectedKey == nil {
                VStack(spacing: 6) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("从左侧选择一个 key 查看其值")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextEditor(text: isValueEditable ? $queryValue : .constant(queryValue))
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .disabled(!isValueEditable)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.94, green: 0.94, blue: 0.95).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Derived

    private var totalKeyCount: Int { boxModel.boxData.datas.count }

    private var recentKeys: [String] {
        deduped(boxModel.boxData.usercfgs?.viewkeys ?? [])
    }

    private var externalKeys: [String] {
        deduped(boxModel.boxData.usercfgs?.gist_cache_key ?? [])
    }

    private var filteredKeys: [String] {
        let needle = queryKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return boxModel.boxData.datas.keys
            .filter { $0.lowercased().contains(needle) }
            .sorted()
            .prefix(50)
            .map { $0 }
    }

    private var ownerAppName: String? {
        guard let key = selectedKey else { return nil }
        return keyToOwnerMap[key]
    }

    private var keyToOwnerMap: [String: String] {
        var map: [String: String] = [:]
        for sub in boxModel.boxData.appSubCaches.values {
            for app in sub.apps {
                for key in (app.keys ?? []) + (app.settings ?? []).map(\.id) {
                    map[key] = app.name
                }
            }
        }
        for app in boxModel.boxData.sysapps {
            for key in (app.keys ?? []) + (app.settings ?? []).map(\.id) {
                map[key] = app.name
            }
        }
        return map
    }

    private var valueTypeLabel: String {
        guard selectedKey != nil else { return "" }
        if queryValue.isEmpty { return "空" }
        if isValueEditable { return "字符串" }
        return "JSON"
    }

    private var valueSizeLabel: String {
        guard selectedKey != nil, !queryValue.isEmpty else { return "" }
        let bytes = queryValue.utf8.count
        if bytes >= 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / 1_048_576.0)
        }
        if bytes >= 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        }
        return "\(bytes) B"
    }

    // MARK: - Subtitles

    private func rowSubtitle(for key: String, source: KeySource) -> String {
        let owner = keyToOwnerMap[key]
        let preview = dataPreview(boxModel.boxData.datas[key] ?? nil)
        let truncatedPreview: String? = {
            guard !preview.isEmpty, preview != "null" else { return nil }
            if preview.count > 36 { return String(preview.prefix(36)) + "…" }
            return preview
        }()

        switch (owner, truncatedPreview) {
        case let (owner?, preview?):
            return "\(owner) · \(preview)"
        case let (owner?, nil):
            return owner
        case let (nil, preview?):
            return preview
        case (nil, nil):
            switch source {
            case .recent:   return "近期"
            case .external: return "非订阅"
            case .search:   return "搜索结果"
            }
        }
    }

    // MARK: - Actions

    private func selectKey(_ key: String) {
        guard !key.isEmpty else { return }
        selectedKey = key
        queryKey = key
        addToViewKeys(key)
        queryData(key: key)
    }

    private func queryData(key: String) {
        Task {
            do {
                let resp: DataQueryResp = try await NetworkProvider.request(.queryData(key: key))
                await MainActor.run { applyValue(resp.val) }
            } catch {
                await MainActor.run { toastManager.showToast(message: "查询失败") }
            }
        }
    }

    private func applyValue(_ value: AnyCodable?) {
        guard let value else {
            queryValue = ""
            isValueEditable = true
            return
        }
        if let string = value.value as? String {
            queryValue = string
            isValueEditable = true
            return
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(value),
           let string = String(data: data, encoding: .utf8) {
            queryValue = string
        } else {
            queryValue = String(describing: value.value)
        }
        isValueEditable = false
    }

    private func saveData() {
        guard let selectedKey, !selectedKey.isEmpty else { return }
        isSaving = true
        let value = queryValue
        Task {
            do {
                let _: DataQueryResp = try await NetworkProvider.request(.saveDataKV(key: selectedKey, val: value))
                await boxModel.fetchDataAsync()
                await MainActor.run {
                    isSaving = false
                    toastManager.showToast(message: "保存成功")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    toastManager.showToast(message: "保存失败")
                }
            }
        }
    }

    private func addToViewKeys(_ key: String) {
        var keys = boxModel.boxData.usercfgs?.viewkeys ?? []
        keys.removeAll { $0 == key }
        keys.insert(key, at: 0)
        boxModel.updateData(path: "usercfgs.viewkeys", data: keys)
        Task { await boxModel.flushPendingDataUpdates() }
    }

    private func removeStoredKey(_ key: String, source: KeySource) {
        let path: String
        let sourceKeys: [String]
        switch source {
        case .recent:
            path = "usercfgs.viewkeys"
            sourceKeys = boxModel.boxData.usercfgs?.viewkeys ?? []
        case .external:
            path = "usercfgs.gist_cache_key"
            sourceKeys = boxModel.boxData.usercfgs?.gist_cache_key ?? []
        case .search:
            return
        }
        var keys = sourceKeys
        keys.removeAll { $0 == key }
        boxModel.updateData(path: path, data: keys)
        Task { await boxModel.flushPendingDataUpdates() }
        if selectedKey == key { selectedKey = nil }
    }

    private func dataPreview(_ value: AnyCodable?) -> String {
        guard let value else { return "null" }
        if let string = value.value as? String {
            return string.replacingOccurrences(of: "\n", with: " ")
        }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return String(describing: value.value)
    }

    private func deduped(_ keys: [String]) -> [String] {
        var seen = Set<String>()
        return keys.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
