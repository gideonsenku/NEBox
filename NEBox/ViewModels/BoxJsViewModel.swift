//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI
import AnyCodable

class BoxJsViewModel: ObservableObject {
    @Published var boxData: BoxDataResp
    @Published var isDataLoaded = false

    var favApps: [AppModel] { boxData.favApps }

    var toastManager: ToastManager?
    private let iconThemeIdx = 0
    private var pendingDataUpdates: [String: Any] = [:]
    private var isFlushingPendingDataUpdates = false

    init(boxData: BoxDataResp = BoxDataResp(
        appSubCaches: [:],
        datas: [:],
        sessions: [],
        usercfgs: UserConfig(appsubs: [], favapps: [], bgimgs: "", bgimg: "", name: nil, icon: nil, viewkeys: nil, gist_cache_key: nil, theme: nil, isTransparentIcons: nil, isWallpaperMode: nil, isMute: nil, isMuteQueryAlert: nil, isHideHelp: nil, isHideBoxIcon: nil, isHideMyTitle: nil, isHideCoding: nil, isHideRefresh: nil, isDebugWeb: nil, lang: nil, httpapi: nil, httpapis: nil),
        sysapps: [],
        globalbaks: nil,
        curSessions: nil,
        syscfgs: nil
    )) {
        self.boxData = boxData
    }

    @MainActor
    private func updateBoxData(_ boxdata: BoxDataResp) {
        self.boxData = boxdata
    }

    @MainActor
    func reset() {
        isDataLoaded = false
    }

    // MARK: - Generic Error Handling

    @MainActor
    private func perform(_ hint: String, _ operation: () async throws -> BoxDataResp) async {
        do {
            let boxdata = try await operation()
            self.boxData = boxdata
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            toastManager?.showToast(message: "\(hint)失败")
            appLog(.error, category: .viewModel, "[\(hint)] \(msg)")
        }
    }

    // MARK: - Data Fetching

    func fetchData() {
        Task {
            appLog(.info, category: .viewModel, "[fetchData] start, baseURL: \(ApiManager.shared.baseURL)")
            do {
                let boxdata: BoxDataResp = try await NetworkProvider.request(.getBoxData)
                await updateBoxData(boxdata)
                await MainActor.run { self.isDataLoaded = true }
                appLog(.info, category: .viewModel, "[fetchData] success")
            } catch {
                await MainActor.run {
                    self.isDataLoaded = true
                    toastManager?.showToast(message: "加载数据失败")
                }
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                appLog(.error, category: .viewModel, "[fetchData] failed, baseURL: \(ApiManager.shared.baseURL), error: \(msg)")
            }
        }
    }

    /// Fire-and-forget version (existing callers)
    func updateData(path: String, data: Any) {
        if path.hasPrefix("usercfgs.") {
            applyOptimisticUsercfgsUpdate(path: path, data: data)
        }
        pendingDataUpdates[path] = data
    }

    @discardableResult
    func flushPendingDataUpdates() async -> Bool {
        guard !isFlushingPendingDataUpdates else { return false }
        guard !pendingDataUpdates.isEmpty else { return true }

        isFlushingPendingDataUpdates = true
        let updates = pendingDataUpdates
        pendingDataUpdates.removeAll()
        defer { isFlushingPendingDataUpdates = false }

        var failedUpdates: [String: Any] = [:]

        for (path, data) in updates {
            do {
                let _: BoxDataResp = try await NetworkProvider.request(.updateData(path: path, val: data))
            } catch let error as RequestError {
                if case .decodeFail = error {
                    continue
                }
                failedUpdates[path] = data
                appLog(.error, category: .viewModel, "[flushPendingDataUpdates] write failed for \(path): \(error)")
            } catch {
                failedUpdates[path] = data
                appLog(.error, category: .viewModel, "[flushPendingDataUpdates] write failed for \(path): \(error)")
            }
        }

        if !failedUpdates.isEmpty {
            for (path, data) in failedUpdates {
                pendingDataUpdates[path] = data
            }
            await MainActor.run {
                toastManager?.showToast(message: "部分更新失败，已保留待重试")
            }
            return false
        }

        do {
            let boxdata: BoxDataResp = try await NetworkProvider.request(.getBoxData)
            await updateBoxData(boxdata)
            return true
        } catch {
            appLog(.error, category: .viewModel, "[flushPendingDataUpdates] refetch failed: \(error)")
            return true
        }
    }

    /// 先改本地 `usercfgs`，避免 Toggle 等控件等网络往返才刷新
    private func applyOptimisticUsercfgsUpdate(path: String, data: Any) {
        guard path.hasPrefix("usercfgs.") else { return }
        let suffix = String(path.dropFirst("usercfgs.".count))
        guard let cfg = boxData.usercfgs,
              let updated = cfg.updating(pathSuffix: suffix, value: data) else { return }
        boxData = boxData.replacingUsercfgs(updated)
    }

    enum UpdateError: Error {
        case writeFailed(underlying: Error)
        case refetchFailed(underlying: Error)
    }

    /// Async version with explicit error propagation
    @discardableResult
    func updateDataAsync(path: String, data: Any) async -> Result<Void, UpdateError> {
        var writeSucceeded = false
        do {
            let boxdata: BoxDataResp = try await NetworkProvider.request(.updateData(path: path, val: data))
            await updateBoxData(boxdata)
            writeSucceeded = true
        } catch let error as RequestError {
            if case .decodeFail = error {
                writeSucceeded = true
            } else {
                return .failure(.writeFailed(underlying: error))
            }
        } catch {
            return .failure(.writeFailed(underlying: error))
        }

        do {
            let boxdata: BoxDataResp = try await NetworkProvider.request(.getBoxData)
            await updateBoxData(boxdata)
            return .success(())
        } catch {
            return writeSucceeded ? .success(()) : .failure(.refetchFailed(underlying: error))
        }
    }

    // MARK: - 订阅管理

    func reloadAppSub(url: String) async {
        await perform("刷新订阅") { try await NetworkProvider.request(.reloadAppSub(url: url)) }
    }

    func reloadAllAppSub() async {
        await perform("刷新全部订阅") { try await NetworkProvider.request(.reloadAllAppSub) }
    }

    func addAppSub(url: String) async {
        await perform("添加订阅") { try await ApiRequest.addAppSub(url: url) }
    }

    func deleteAppSub(url: String) async {
        await perform("删除订阅") { try await NetworkProvider.request(.deleteAppSub(url: url)) }
    }

    // MARK: - 数据保存

    func saveData(params: [SessionData]) async {
        await perform("保存数据") { try await NetworkProvider.request(.saveData(params: params)) }
    }

    // MARK: - 全局备份

    func saveGlobalBak() async {
        let name = "全局备份 \((boxData.globalbaks?.count ?? 0) + 1)"
        await perform("保存备份") {
            try await ApiRequest.saveGlobalBak(name: name, env: "", version: "", versionType: "")
        }
    }

    func delGlobalBak(id: String) async {
        await perform("删除备份") { try await NetworkProvider.request(.delGlobalBak(id: id)) }
    }

    func revertGlobalBak(id: String) async {
        await perform("恢复备份") { try await NetworkProvider.request(.revertGlobalBak(id: id)) }
    }

    func updateGlobalBak(id: String, name: String) async {
        await perform("更新备份") { try await NetworkProvider.request(.updateGlobalBak(id: id, name: name)) }
    }

    func impGlobalBak(bakData: String) async {
        let name = "全局备份 \((boxData.globalbaks?.count ?? 0) + 1)"
        await perform("导入备份") { try await ApiRequest.impGlobalBak(bakData: bakData, name: name) }
    }

    // MARK: - 会话管理

    func saveAppSession(app: AppModel, datas: [SessionData]) async {
        let session = Session(
            id: UUID().uuidString,
            name: "会话 \(boxData.sessions.filter { $0.appId == app.id }.count + 1)",
            enable: true,
            appId: app.id,
            appName: app.name,
            createTime: ISO8601DateFormatter().string(from: Date()),
            datas: datas
        )
        var allSessions = boxData.sessions
        allSessions.append(session)
        await perform("保存会话") { try await ApiRequest.saveSessions(allSessions) }
    }

    func delAppSession(sessionId: String) async {
        var allSessions = boxData.sessions
        allSessions.removeAll { $0.id == sessionId }
        await perform("删除会话") { try await ApiRequest.saveSessions(allSessions) }
    }

    func updateAppSession(_ session: Session) async {
        var allSessions = boxData.sessions
        if let idx = allSessions.firstIndex(where: { $0.id == session.id }) {
            allSessions[idx] = session
        }
        await perform("更新会话") { try await ApiRequest.saveSessions(allSessions) }
    }

    func useAppSession(sessionId: String, appId: String) async {
        guard let session = boxData.sessions.first(where: { $0.id == sessionId }) else { return }
        var datas = session.datas
        datas.append(SessionData(key: "chavy_boxjs_cur_sessions", val: AnyCodable("{}")))
        await perform("应用会话") { try await NetworkProvider.request(.useAppSession(datas: datas, appId: appId)) }
    }

    func linkAppSession(sessionId: String, appId: String) async {
        guard let session = boxData.sessions.first(where: { $0.id == sessionId }) else { return }
        var curSessions = boxData.curSessions ?? [:]
        curSessions[appId] = sessionId
        let curSessionsJSON = (try? JSONEncoder().encode(curSessions)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        var datas = session.datas
        datas.append(SessionData(key: "chavy_boxjs_cur_sessions", val: AnyCodable(curSessionsJSON)))
        await perform("关联会话") { try await NetworkProvider.request(.linkAppSession(datas: datas)) }
    }

    func clearAppDatas(app: AppModel, key: String? = nil) async {
        let dataInfo = boxData.loadAppDataInfo(for: app)
        var datas: [SessionData]
        if let key = key {
            datas = dataInfo.datas.map { d in
                d.key == key ? SessionData(key: d.key, val: AnyCodable("")) : d
            }
        } else {
            datas = dataInfo.datas.map { d in
                SessionData(key: d.key, val: AnyCodable(""))
            }
        }
        await saveData(params: datas)
    }

    func impAppDatas(jsonString: String) async {
        guard let jsonData = jsonString.data(using: .utf8),
              let impapp = try? JSONDecoder().decode(AppModel.self, from: jsonData) else { return }
        var datas: [SessionData] = []
        if let settings = impapp.settings {
            datas = settings.map { SessionData(key: $0.id, val: $0.val) }
        }
        await saveData(params: datas)
    }
}
