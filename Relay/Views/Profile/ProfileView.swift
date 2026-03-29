//
//  ProfileView.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI
import SDWebImageSwiftUI
import AnyCodable
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

    var body: some View {
        neboxNavigationContainer {
            ZStack(alignment: .top) {
                // Gradient background — matches HomeView
                LinearGradient(
                    colors: [Color(hex: "#EEF0FA"), Color(hex: "#F0EDF8"), Color(hex: "#F5F0F8")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Spacer for nav bar
                        Color.clear.frame(height: 56)

                        // Profile header card
                        profileHeaderCard

                        // Stats row
                        statsRow

                        // Quick actions
                        quickActionsCard

                        // Backup section
                        backupSection

                        // Bottom padding for tab bar
                        Color.clear.frame(height: adaptiveBottomInset())
                    }
                    .padding(.horizontal, 20)
                }

                // Nav bar on top
                VStack {
                    navBar
                        .background(Color(hex: "#EEF0FA").ignoresSafeArea())
                    Spacer()
                }
            }
            .neboxHiddenNavigationBar()
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
            .sheet(isPresented: $showImportBak) {
                importBakSheet
            }
            .sheet(isPresented: $showApiSettings) {
                ApiSettingsView()
            }
        }
        .neboxLiquidGlassTabBarChrome()
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#E8EAF4"))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#002FA7"))
                }
                Text("我的")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1918"))
            }

            Spacer()

            // Settings button
            Button {
                showApiSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#002FA7"))
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }

    // MARK: - Profile Header Card

    private var profileHeaderCard: some View {
        HStack(spacing: 16) {
            // Avatar
            if let iconUrl = boxModel.boxData.usercfgs?.icon,
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
                            colors: [Color(hex: "#002FA7"), Color(hex: "#0047D4")],
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

            VStack(alignment: .leading, spacing: 4) {
                Text(boxModel.boxData.usercfgs?.name ?? "大侠, 请留名!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A1918"))

                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text(apiManager.apiUrl ?? "未连接")
                        .lineLimit(1)
                }
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#9098AD"))
            }

            Spacer()

            Button {
                editName = boxModel.boxData.usercfgs?.name ?? ""
                editIcon = boxModel.boxData.usercfgs?.icon ?? ""
                showEditProfile = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#002FA7").opacity(0.8))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(icon: "app.badge", label: "应用", count: boxModel.boxData.apps.count, color: Color(hex: "#002FA7"))
            StatCard(icon: "square.stack", label: "订阅", count: boxModel.boxData.displayAppSubs.count, color: Color(hex: "#7C3AED"))
            StatCard(icon: "person.2", label: "会话", count: boxModel.boxData.sessions.count, color: Color(hex: "#059669"))
        }
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("工具")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#9098AD"))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                NavigationLink(destination: PreferencesView()) {
                    ActionRow(icon: "slider.horizontal.3", title: "偏好设置", subtitle: "自定义 BoxJs 行为")
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: ScriptEditorView()) {
                    ActionRow(icon: "chevron.left.forwardslash.chevron.right", title: "脚本编辑", subtitle: "编辑和运行脚本")
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: DataViewerView()) {
                    ActionRow(icon: "cylinder", title: "数据查看", subtitle: "查看存储数据")
                }
                Divider().padding(.leading, 52)

                NavigationLink(destination: LogViewerView()) {
                    ActionRow(icon: "doc.text.magnifyingglass", title: "日志", subtitle: "查看和导出应用日志")
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Backup Section

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("备份")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#9098AD"))

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        showImportBak = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12))
                            Text("导入")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#002FA7"))
                    }

                    Button {
                        Task {
                            await boxModel.saveGlobalBak()
                            toastManager.showToast(message: "备份成功!")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                            Text("创建")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#002FA7"))
                    }
                }
            }
            .padding(.horizontal, 4)

            if let baks = boxModel.boxData.globalbaks, !baks.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(baks.enumerated()), id: \.element.id) { index, bak in
                        NavigationLink(destination: BackupDetailView(backup: bak)) {
                            BackupRow(backup: bak, formatTime: formatBackupTime)
                        }

                        if index < baks.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "externaldrive.badge.timemachine")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#9098AD").opacity(0.5))
                        Text("暂无备份")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#9098AD"))
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Edit Profile Sheet

    private var editProfileSheet: some View {
        neboxNavigationContainer {
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
        neboxNavigationContainer {
            Form {
                Section(footer: Text("支持 JSON 格式的备份数据")) {
                    Button {
                        guard let str = UIPasteboard.general.string, !str.isEmpty else {
                            toastManager.showToast(message: "剪贴板为空")
                            return
                        }
                        importBakText = str
                        performImportBak()
                    } label: {
                        Label("从剪贴板粘贴", systemImage: "doc.on.clipboard")
                    }

                    Button {
                        showImportFilePickerBak = true
                    } label: {
                        Label("从文件导入", systemImage: "doc")
                    }
                }

                if !importBakText.isEmpty {
                    Section(header: Text("数据预览")) {
                        Text(importBakText.prefix(500) + (importBakText.count > 500 ? "..." : ""))
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
                    Button("取消") {
                        showImportBak = false
                        importBakText = ""
                    }
                }
            }
            .fileImporter(
                isPresented: $showImportFilePickerBak,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let str = String(data: data, encoding: .utf8), !str.isEmpty {
                        importBakText = str
                        performImportBak()
                    } else {
                        toastManager.showToast(message: "文件读取失败")
                    }
                }
            }
        }
    }

    private func performImportBak() {
        guard !importBakText.isEmpty else { return }
        Task {
            await boxModel.impGlobalBak(bakData: importBakText)
            toastManager.showToast(message: "导入成功!")
            showImportBak = false
            importBakText = ""
        }
    }

    // MARK: - Helpers

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFallback = ISO8601DateFormatter()
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private func formatBackupTime(_ isoString: String) -> String {
        if let date = Self.isoFractional.date(from: isoString) {
            return Self.displayFormatter.string(from: date)
        }
        if let date = Self.isoFallback.date(from: isoString) {
            return Self.displayFormatter.string(from: date)
        }
        return isoString
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
                    .foregroundColor(Color(hex: "#1A1918"))
            }
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9098AD"))
                Spacer()
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "#F5F5F7"))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#002FA7"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#1A1918"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9098AD"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#C7C7CC"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 36, height: 36)
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#059669"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(backup.name)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#1A1918"))
                    .lineLimit(1)

                if let createTime = backup.createTime {
                    Text(formatTime(createTime))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#9098AD"))
                }
            }

            Spacer()

            if let tags = backup.tags, !tags.filter({ !$0.isEmpty }).isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.filter { !$0.isEmpty }.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#F3F4F6"))
                            .clipShape(Capsule())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#C7C7CC"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
    @State private var exportFileURL: URL? = nil
    @State private var showExportShare = false

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

                Button {
                    if exportFileURL != nil {
                        showExportShare = true
                    } else {
                        toastManager.showToast(message: "备份数据加载中...")
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoadingBak && exportFileURL == nil {
                            ProgressView()
                                .frame(height: 20)
                        } else {
                            Text("导出 JSON 文件")
                        }
                        Spacer()
                    }
                }
                .disabled(exportFileURL == nil)
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
        .background(
            ActivityViewPresenter(isPresented: $showExportShare, items: exportFileURL.map { [$0] } ?? [])
        )
        .onAppear {
            editedName = backup.name
            prepareExportFile(from: backup.bak)
            loadBakData()
        }
    }

    private func loadBakData() {
        guard bakData == nil, backup.bak == nil else { return }
        isLoadingBak = true
        Task {
            do {
                let data: AnyCodable = try await NetworkProvider.request(.loadGlobalBak(id: backup.id))
                await MainActor.run {
                    bakData = data
                    isLoadingBak = false
                    prepareExportFile(from: data)
                }
            } catch {
                await MainActor.run { isLoadingBak = false }
                appLog(.error, category: .viewModel, "Failed to load backup data: \(error)")
            }
        }
    }

    private func prepareExportFile(from bak: AnyCodable?) {
        guard let bak = bak, exportFileURL == nil else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(bak) {
            let fileName = "\(backup.name)_\(backup.id).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try? data.write(to: tempURL)
            exportFileURL = tempURL
        }
    }
}

// MARK: - Activity View Presenter

/// Bridges UIActivityViewController into SwiftUI via a hidden UIViewController.
/// The host VC sits invisibly in the view hierarchy, so `present()` works
/// correctly and the share sheet slides up from the bottom as expected.
/// Compatible with iOS 15+.
private struct ActivityViewPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        if isPresented {
            // Prevent presenting twice
            guard host.presentedViewController == nil else { return }
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            ac.completionWithItemsHandler = { _, _, _, _ in
                isPresented = false
            }
            host.present(ac, animated: true)
        } else {
            if host.presentedViewController is UIActivityViewController {
                host.dismiss(animated: true)
            }
        }
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
