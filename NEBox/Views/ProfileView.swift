//
//  ProfileView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import SDWebImageSwiftUI
import AnyCodable

// MARK: - Profile Main View

struct ProfileView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var showEditProfile = false
    @State private var showImportBak = false
    @State private var importBakText = ""
    @State private var editName = ""
    @State private var editIcon = ""

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(urlString: boxModel.boxData.bgImgUrl)
                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        backupListCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("我的")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: name + edit button
            HStack {
                if let iconUrl = boxModel.boxData.usercfgs?.icon,
                   !iconUrl.isEmpty,
                   let url = URL(string: iconUrl) {
                    WebImage(url: url)
                        .resizable()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(boxModel.boxData.usercfgs?.name ?? "大侠, 请留名!")
                        .font(.headline)
                    Text("BoxJs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    editName = boxModel.boxData.usercfgs?.name ?? ""
                    editIcon = boxModel.boxData.usercfgs?.icon ?? ""
                    showEditProfile = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Data stats
            Text("我的数据")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                StatChip(label: "应用", count: boxModel.boxData.apps.count)
                StatChip(label: "订阅", count: boxModel.boxData.displayAppSubs.count)
                StatChip(label: "会话", count: boxModel.boxData.sessions.count)
            }

            Divider()

            // Actions
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 8) {
                NavigationLink(destination: PreferencesView()) {
                    profileActionLabel("偏好设置", icon: "gearshape")
                }
                NavigationLink(destination: ScriptEditorView()) {
                    profileActionLabel("脚本编辑", icon: "chevron.left.forwardslash.chevron.right")
                }
                NavigationLink(destination: DataViewerView()) {
                    profileActionLabel("数据查看", icon: "cylinder")
                }
                Button { showImportBak = true } label: {
                    profileActionLabel("导入备份", icon: "square.and.arrow.down")
                }
                Button {
                    Task {
                        await boxModel.saveGlobalBak()
                        toastManager.showToast(message: "备份成功!")
                    }
                } label: {
                    profileActionLabel("创建备份", icon: "externaldrive.badge.plus", highlight: true)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showEditProfile) {
            editProfileSheet
        }
        .sheet(isPresented: $showImportBak) {
            importBakSheet
        }
    }

    // MARK: - Backup List

    private var backupListCard: some View {
        Group {
            if let baks = boxModel.boxData.globalbaks, !baks.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(baks.enumerated()), id: \.element.id) { index, bak in
                        NavigationLink(destination: BackupDetailView(backup: bak)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bak.name)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)

                                    if let createTime = bak.createTime {
                                        Text(formatBackupTime(createTime))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let tags = bak.tags, !tags.isEmpty {
                                        HStack(spacing: 4) {
                                            ForEach(tags.filter { !$0.isEmpty }, id: \.self) { tag in
                                                Text(tag)
                                                    .font(.system(size: 10))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color(.systemGray5))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }

                        if index < baks.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
            }
        }
    }

    // MARK: - Edit Profile Sheet

    private var editProfileSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("个人资料")) {
                    TextField("昵称", text: $editName)
                    TextField("头像链接 (可选)", text: $editIcon)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showEditProfile = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let params = [
                            SessionData(key: "chavy_boxjs_userCfgs_name", val: AnyCodable(editName)),
                            SessionData(key: "chavy_boxjs_userCfgs_icon", val: AnyCodable(editIcon))
                        ]
                        // Save via usercfgs update
                        boxModel.updateData(path: "usercfgs.name", data: editName)
                        boxModel.updateData(path: "usercfgs.icon", data: editIcon)
                        showEditProfile = false
                        toastManager.showToast(message: "保存成功!")
                    }
                }
            }
        }
    }

    // MARK: - Import Backup Sheet

    private var importBakSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("导入备份"), footer: Text("粘贴备份数据 (JSON 格式)")) {
                    TextEditor(text: $importBakText)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("导入备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showImportBak = false
                        importBakText = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        guard !importBakText.isEmpty else { return }
                        Task {
                            await boxModel.impGlobalBak(bakData: importBakText)
                            toastManager.showToast(message: "导入成功!")
                            showImportBak = false
                            importBakText = ""
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func profileActionLabel(_ title: String, icon: String, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(highlight ? .accentColor : .secondary)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(highlight ? .accentColor : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(highlight ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
    }

    private func formatBackupTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            let fallback = ISO8601DateFormatter()
            guard let d = fallback.date(from: isoString) else { return isoString }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df.string(from: d)
        }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: date)
    }
}

// MARK: - Stat Chip

struct StatChip: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Backup Detail View

struct BackupDetailView: View {
    let backup: GlobalBackup

    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.presentationMode) var presentationMode

    @State private var editedName: String = ""
    @State private var bakData: AnyCodable? = nil
    @State private var isLoadingBak = false

    var body: some View {
        Form {
            Section(header: Text("备份信息")) {
                HStack {
                    Text("备份索引")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(backup.id)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("备份名称")
                    Spacer()
                    TextField("名称", text: $editedName)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            Task {
                                await boxModel.updateGlobalBak(id: backup.id, name: editedName)
                                toastManager.showToast(message: "已更新")
                            }
                        }
                }

                if let createTime = backup.createTime {
                    HStack {
                        Text("创建时间")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(createTime)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                if let tags = backup.tags, !tags.isEmpty {
                    HStack {
                        Text("标签")
                            .foregroundColor(.secondary)
                        Spacer()
                        ForEach(tags.filter { !$0.isEmpty }, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await boxModel.revertGlobalBak(id: backup.id)
                        toastManager.showToast(message: "恢复成功!")
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("恢复此备份")
                        Spacer()
                    }
                }

                Button {
                    if let bak = bakData ?? backup.bak {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        if let data = try? encoder.encode(bak),
                           let str = String(data: data, encoding: .utf8) {
                            copyToClipboard(text: str)
                            toastManager.showToast(message: "已复制备份数据")
                        }
                    } else {
                        toastManager.showToast(message: "备份数据加载中...")
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoadingBak {
                            ProgressView()
                                .frame(height: 20)
                        } else {
                            Text("复制备份数据")
                        }
                        Spacer()
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await boxModel.delGlobalBak(id: backup.id)
                        toastManager.showToast(message: "已删除")
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("删除备份")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(backup.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedName = backup.name
            loadBakData()
        }
    }

    private func loadBakData() {
        guard bakData == nil, backup.bak == nil else { return }
        isLoadingBak = true
        Task {
            do {
                let data = try await ApiRequest.loadGlobalBak(id: backup.id)
                await MainActor.run {
                    bakData = data
                    isLoadingBak = false
                }
            } catch {
                await MainActor.run { isLoadingBak = false }
                print("Failed to load backup data: \(error)")
            }
        }
    }
}
