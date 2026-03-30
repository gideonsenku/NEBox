//
//  ProfileView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import SDWebImageSwiftUI
import UniformTypeIdentifiers

// MARK: - Profile Main View

struct ProfileView: View {
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var apiManager: ApiManager

    @State private var showEditProfile = false
    @State private var showImportBak = false
    @State private var showApiSettings = false
    @State private var importBakText = ""
    @State private var showImportFilePickerBak = false
    @State private var editName = ""
    @State private var editIcon = ""
    @State private var showCreateBak = false
    @State private var newBakName = ""

    var body: some View {
        neboxNavigationContainer {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: Color.pageGradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Color.clear.frame(height: 56)

                        ProfileHeaderCard(
                            usercfgs: boxModel.boxData.usercfgs,
                            apiUrl: apiManager.apiUrl,
                            onEdit: presentEditProfile
                        )

                        ProfileStatsRow(
                            appCount: boxModel.cachedApps.count,
                            subCount: boxModel.cachedAppSubSummaries.count,
                            sessionCount: boxModel.boxData.sessions.count
                        )

                        ProfileQuickActions()

                        ProfileBackupSection(
                            backups: boxModel.boxData.globalbaks,
                            onImport: { showImportBak = true },
                            onCreate: presentCreateBackup,
                            formatTime: formatBackupTime
                        )

                        ProfileOtherSection()

                        ProfileVersionFooter()

                        Color.clear.frame(height: adaptiveBottomInset())
                    }
                    .padding(.horizontal, 20)
                }

                VStack {
                    ProfileNavBar(onSettings: { showApiSettings = true })
                        .background(Color.gradientTop.ignoresSafeArea())
                    Spacer()
                }
            }
            .neboxHiddenNavigationBar()
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(
                    name: $editName,
                    icon: $editIcon,
                    onSave: saveProfile,
                    onCancel: { showEditProfile = false }
                )
            }
            .sheet(isPresented: $showImportBak) {
                ImportBackupSheet(
                    importText: $importBakText,
                    showFilePicker: $showImportFilePickerBak,
                    onImport: performImportBak,
                    onCancel: cancelImport
                )
                .neboxMediumSheet()
            }
            .sheet(isPresented: $showApiSettings) {
                ApiSettingsView()
            }
            .alert("创建备份", isPresented: $showCreateBak) {
                TextField("备份名称", text: $newBakName)
                Button("取消", role: .cancel) { newBakName = "" }
                Button("创建") { createBackup() }
            } message: {
                Text("请输入备份名称")
            }
        }
        .neboxLiquidGlassTabBarChrome()
    }
}

// MARK: - ProfileView Actions

private extension ProfileView {
    func presentEditProfile() {
        editName = boxModel.boxData.usercfgs?.name ?? ""
        editIcon = boxModel.boxData.usercfgs?.icon ?? ""
        showEditProfile = true
    }

    func saveProfile() {
        showEditProfile = false
        Task {
            let r1 = await boxModel.updateDataAsync(path: "usercfgs.name", data: editName)
            let r2 = await boxModel.updateDataAsync(path: "usercfgs.icon", data: editIcon)
            if case .failure = r1 { toastManager.showToast(message: "保存失败"); return }
            if case .failure = r2 { toastManager.showToast(message: "保存失败"); return }
            toastManager.showToast(message: "保存成功!")
        }
    }

    func presentCreateBackup() {
        newBakName = "全局备份 \((boxModel.boxData.globalbaks?.count ?? 0) + 1)"
        showCreateBak = true
    }

    func createBackup() {
        let name = newBakName.trimmingCharacters(in: .whitespacesAndNewlines)
        newBakName = ""
        Task {
            await boxModel.saveGlobalBak(name: name.isEmpty ? nil : name)
        }
    }

    func performImportBak() {
        guard !importBakText.isEmpty else { return }
        Task {
            await boxModel.impGlobalBak(bakData: importBakText)
            showImportBak = false
            importBakText = ""
        }
    }

    func cancelImport() {
        showImportBak = false
        importBakText = ""
    }
}

// MARK: - ProfileView Helpers

private extension ProfileView {
    static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let isoFallback = ISO8601DateFormatter()

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    func formatBackupTime(_ isoString: String) -> String {
        if let date = Self.isoFractional.date(from: isoString) {
            return Self.displayFormatter.string(from: date)
        }
        if let date = Self.isoFallback.date(from: isoString) {
            return Self.displayFormatter.string(from: date)
        }
        return isoString
    }
}

// MARK: - Profile Nav Bar

private struct ProfileNavBar: View {
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bgMuted)
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accent)
                }
                Text("我的")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accent)
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }
}

// MARK: - Profile Header Card

private struct ProfileHeaderCard: View {
    let usercfgs: UserConfig?
    let apiUrl: String?
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                Text(usercfgs?.name ?? "大侠, 请留名!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text(apiUrl ?? "未连接")
                        .lineLimit(1)
                }
                .font(.system(size: 12))
                .foregroundColor(.textTertiary)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accent.opacity(0.8))
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let iconUrl = usercfgs?.icon,
           !iconUrl.isEmpty,
           let url = URL(string: iconUrl) {
            WebImage(url: url)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        } else {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.accentBlue, .accentBlueDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}

// MARK: - Profile Stats Row

private struct ProfileStatsRow: View {
    let appCount: Int
    let subCount: Int
    let sessionCount: Int

    var body: some View {
        HStack(spacing: 12) {
            StatCard(icon: "app.badge", label: "应用", count: appCount, color: .accent)
            StatCard(icon: "square.stack", label: "订阅", count: subCount, color: Color.accentCoral)
            StatCard(icon: "person.2", label: "会话", count: sessionCount, color: Color.accentBlue)
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
                Spacer()
            }
        }
        .padding(12)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}

// MARK: - Quick Actions Card

private struct ProfileQuickActions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("工具")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textTertiary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                NavigationLink(destination: PreferencesView()) {
                    ActionRow(icon: "slider.horizontal.3", title: "偏好设置", subtitle: "自定义 BoxJs 行为", iconColor: .gray)
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: ScriptEditorView()) {
                    ActionRow(icon: "chevron.left.forwardslash.chevron.right", title: "脚本编辑", subtitle: "编辑和运行脚本", iconColor: .green)
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: DataViewerView()) {
                    ActionRow(icon: "cylinder", title: "数据查看", subtitle: "查看存储数据", iconColor: .purple)
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: LogViewerView()) {
                    ActionRow(icon: "doc.text.magnifyingglass", title: "日志", subtitle: "查看和导出应用日志", iconColor: .orange)
                }
            }
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

        }
    }
}

// MARK: - Other Section

private struct ProfileOtherSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textTertiary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://ifdian.net/a/gidoensenku")!) {
                    ActionRow(icon: "heart.fill", title: "赞助开发者", subtitle: "请开发者喝杯咖啡", iconColor: .red)
                }
                Divider().padding(.leading, 52)

                Link(destination: URL(string: "https://github.com/gideonsenku/Relay")!) {
                    ActionRow(icon: "star.fill", title: "仓库 Star", subtitle: "在 GitHub 上支持我们", iconColor: .orange)
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: VersionHistoryView()) {
                    ActionRow(icon: "clock.arrow.circlepath", title: "BoxJs 更新日志", subtitle: "查看版本历史和更新内容", iconColor: .mint)
                }
                Divider().padding(.leading, 52)

                Link(destination: URL(string: "tg://resolve?domain=Relay_Group")!) {
                    ActionRow(icon: "paperplane.fill", title: "加入 Telegram 群组", subtitle: "交流反馈与功能建议", iconColor: .blue)
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: AcknowledgementsView()) {
                    ActionRow(icon: "hands.clap", title: "致谢", subtitle: "感谢所有贡献者", iconColor: .pink)
                }
            }
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = .accent

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.bgMuted)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.textInactive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Backup Section

private struct ProfileBackupSection: View {
    let backups: [GlobalBackup]?
    let onImport: () -> Void
    let onCreate: () -> Void
    let formatTime: (String) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("备份")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textTertiary)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: onImport) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12))
                            Text("导入")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.accent)
                    }

                    Button(action: onCreate) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                            Text("创建")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.accent)
                    }
                }
            }
            .padding(.horizontal, 4)

            if let baks = backups, !baks.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(baks.enumerated()), id: \.element.id) { index, bak in
                        NavigationLink(destination: BackupDetailView(backup: bak)) {
                            BackupRow(backup: bak, formatTime: formatTime)
                        }

                        if index < baks.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "externaldrive.badge.timemachine")
                            .font(.system(size: 32))
                            .foregroundColor(.textTertiary.opacity(0.5))
                        Text("暂无备份")
                            .font(.system(size: 13))
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

// MARK: - Backup Row

private struct BackupRow: View {
    let backup: GlobalBackup
    let formatTime: (String) -> String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentBlueLight)
                    .frame(width: 36, height: 36)
                Image(systemName: "icloud.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.accentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(backup.name)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                if let createTime = backup.createTime {
                    Text(formatTime(createTime))
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }
            }

            Spacer()

            if let tags = backup.tags?.filter({ !$0.isEmpty }), !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.bgMuted)
                            .clipShape(Capsule())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.textInactive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Edit Profile Sheet

private struct EditProfileSheet: View {
    @Binding var name: String
    @Binding var icon: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        neboxNavigationContainer {
            Form {
                Section(header: Text("个人资料")) {
                    TextField("昵称", text: $name)
                    TextField("头像链接 (可选)", text: $icon)
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: onSave)
                }
            }
        }
    }
}

// MARK: - Import Backup Sheet

private struct ImportBackupSheet: View {
    @EnvironmentObject var toastManager: ToastManager

    @Binding var importText: String
    @Binding var showFilePicker: Bool
    let onImport: () -> Void
    let onCancel: () -> Void

    var body: some View {
        neboxNavigationContainer {
            Form {
                Section(footer: Text("支持 JSON 格式的备份数据")) {
                    Button(action: pasteFromClipboard) {
                        Label("从剪贴板粘贴", systemImage: "doc.on.clipboard")
                    }

                    Button { showFilePicker = true } label: {
                        Label("从文件导入", systemImage: "doc")
                    }
                }

                if !importText.isEmpty {
                    Section(header: Text("数据预览")) {
                        Text(importText.prefix(500) + (importText.count > 500 ? "..." : ""))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(10)
                    }
                }
            }
            .navigationTitle("导入备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func pasteFromClipboard() {
        guard let str = UIPasteboard.general.string, !str.isEmpty else {
            toastManager.showToast(message: "剪贴板为空")
            return
        }
        importText = str
        onImport()
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result, let url = urls.first {
            guard url.startAccessingSecurityScopedResource() else {
                toastManager.showToast(message: "无法访问文件")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url),
               let str = String(data: data, encoding: .utf8), !str.isEmpty {
                importText = str
                onImport()
            } else {
                toastManager.showToast(message: "文件读取失败")
            }
        }
    }
}

// MARK: - Version Footer

private struct ProfileVersionFooter: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    var body: some View {
        Text("Relay v\(version) (\(build))")
            .font(.system(size: 12))
            .foregroundColor(.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

// MARK: - API Settings View

struct ApiSettingsView: View {
    @EnvironmentObject var apiManager: ApiManager
    @EnvironmentObject var boxModel: BoxJsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.dismiss) var dismiss

    @State private var apiUrlInput: String = ""
    @State private var showResetConfirm = false

    var body: some View {
        neboxNavigationContainer {
            Form {
                Section(header: Text("后端地址"), footer: Text("修改后将重新拉取数据")) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                        TextField(ApiManager.defaultAPIURL, text: $apiUrlInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit { saveAndDismiss() }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("重置连接")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("重置后将返回初始配置页")
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
            .navigationTitle("API 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveAndDismiss() }
                        .disabled(apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                apiUrlInput = apiManager.apiUrl ?? ""
            }
            .confirmationDialog("确认重置连接？", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("重置", role: .destructive) {
                    apiManager.apiUrl = nil
                    boxModel.reset()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这将清除已保存的 API 地址，返回初始配置页")
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = apiUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appLog(.info, category: .ui, "[ApiSettings] save host: \(trimmed)")
        apiManager.apiUrl = trimmed
        boxModel.fetchData()
        toastManager.showToast(message: "API 地址已保存")
        dismiss()
    }
}
