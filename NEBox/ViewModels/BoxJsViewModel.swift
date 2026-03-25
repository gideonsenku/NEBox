//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI
import AnyCodable

class BoxJsViewModel: ObservableObject {
    @Published var favApps: [AppModel]
    @Published var boxData: BoxDataResp {
        didSet {
            favApps = boxData.favApps
        }
    }
    @Published var hasError = false
    @Published var isDataLoaded = false

    private let iconThemeIdx = 0

    init(boxData: BoxDataResp = BoxDataResp(
        appSubCaches: [:],
        datas: [:],
        sessions: [],
        usercfgs: UserConfig(appsubs: [], favapps: [], bgimgs: "", bgimg: "", name: nil, icon: nil, viewkeys: nil, gist_cache_key: nil, theme: nil, isTransparentIcons: nil, isWallpaperMode: nil, isMute: nil, isMuteQueryAlert: nil, isHideHelp: nil, isHideBoxIcon: nil, isHideMyTitle: nil, isHideCoding: nil, isHideRefresh: nil, isDebugWeb: nil, lang: nil, httpapi: nil),
        sysapps: [],
        globalbaks: nil,
        curSessions: nil,
        syscfgs: nil
    )) {
        self.boxData = boxData
        favApps = []
    }

    @MainActor
    private func updateBoxData(_ boxdata: BoxDataResp) {
        self.boxData = boxdata
    }

    func reset() {
        favApps = []
        isDataLoaded = false
        hasError = false
    }

func fetchData() {
        Task {
            do {
                let boxdata = try await ApiRequest.getBoxData()
                await updateBoxData(boxdata)
                await MainActor.run { self.isDataLoaded = true }
            } catch {
                await MainActor.run { self.hasError = true; self.isDataLoaded = true }
                print("Error fetching data: \(error)")
            }
        }
    }

    /// Fire-and-forget version (existing callers)
    func updateData(path: String, data: Any) {
        Task {
            let result = await updateDataAsync(path: path, data: data)
            if case .failure(let err) = result {
                print("[updateData] failed for \(path): \(err)")
            }
        }
    }

    enum UpdateError: Error {
        case writeFailed(underlying: Error)
        case refetchFailed(underlying: Error)
    }

    /// Async version with explicit error propagation
    @discardableResult
    func updateDataAsync(path: String, data: Any) async -> Result<Void, UpdateError> {
        // Step 1: send update to backend
        var writeSucceeded = false
        do {
            let boxdata = try await ApiRequest.updateData(path: path, data: data)
            await updateBoxData(boxdata)
            writeSucceeded = true
        } catch let error as RequestError {
            // decodeFail means the HTTP request succeeded but response didn't match BoxDataResp
            // The write likely succeeded; we'll refetch to confirm
            if case .decodeFail = error {
                writeSucceeded = true
            } else {
                return .failure(.writeFailed(underlying: error))
            }
        } catch {
            return .failure(.writeFailed(underlying: error))
        }

        // Step 2: refetch to ensure UI is in sync
        do {
            let boxdata = try await ApiRequest.getBoxData()
            await updateBoxData(boxdata)
            return .success(())
        } catch {
            // Write may have succeeded even if refetch fails
            return writeSucceeded ? .success(()) : .failure(.refetchFailed(underlying: error))
        }
    }

    func reloadAppSub(url: String) async {
        do {
            let boxdata = try await ApiRequest.reloadAppSub(url: url)
            await updateBoxData(boxdata)
        } catch {
            print("Error reloading sub: \(error)")
        }
    }

    func reloadAllAppSub() async {
        do {
            let boxdata = try await ApiRequest.reloadAllAppSub()
            await updateBoxData(boxdata)
        } catch {
            print("Error reloading all subs: \(error)")
        }
    }

    func addAppSub(url: String) async {
        do {
            let boxdata = try await ApiRequest.addAppSub(url: url)
            await updateBoxData(boxdata)
        } catch {
            print("Error adding sub: \(error)")
        }
    }

    func deleteAppSub(url: String) async {
        do {
            let boxdata = try await ApiRequest.deleteAppSub(url: url)
            await updateBoxData(boxdata)
        } catch {
            print("Error deleting sub: \(error)")
        }
    }

    func saveData(params: [SessionData]) async {
        do {
            let boxdata = try await ApiRequest.saveData(parameters: params)
            await updateBoxData(boxdata)
        } catch {
            print("Error saving data: \(error)")
        }
    }

    // MARK: - 全局备份

    func saveGlobalBak() async {
        do {
            let name = "全局备份 \((boxData.globalbaks?.count ?? 0) + 1)"
            let boxdata = try await ApiRequest.saveGlobalBak(name: name, env: "", version: "", versionType: "")
            await updateBoxData(boxdata)
        } catch {
            print("Error saving backup: \(error)")
        }
    }

    func delGlobalBak(id: String) async {
        do {
            let boxdata = try await ApiRequest.delGlobalBak(id: id)
            await updateBoxData(boxdata)
        } catch {
            print("Error deleting backup: \(error)")
        }
    }

    func revertGlobalBak(id: String) async {
        do {
            let boxdata = try await ApiRequest.revertGlobalBak(id: id)
            await updateBoxData(boxdata)
        } catch {
            print("Error reverting backup: \(error)")
        }
    }

    func updateGlobalBak(id: String, name: String) async {
        do {
            let boxdata = try await ApiRequest.updateGlobalBak(id: id, name: name)
            await updateBoxData(boxdata)
        } catch {
            print("Error updating backup: \(error)")
        }
    }

    func impGlobalBak(bakData: String) async {
        do {
            let name = "全局备份 \((boxData.globalbaks?.count ?? 0) + 1)"
            let boxdata = try await ApiRequest.impGlobalBak(bakData: bakData, name: name)
            await updateBoxData(boxdata)
        } catch {
            print("Error importing backup: \(error)")
        }
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
        do {
            let boxdata = try await ApiRequest.saveSessions(allSessions)
            await updateBoxData(boxdata)
        } catch {
            print("Error saving session: \(error)")
        }
    }

    func delAppSession(sessionId: String) async {
        var allSessions = boxData.sessions
        allSessions.removeAll { $0.id == sessionId }
        do {
            let boxdata = try await ApiRequest.saveSessions(allSessions)
            await updateBoxData(boxdata)
        } catch {
            print("Error deleting session: \(error)")
        }
    }

    func updateAppSession(_ session: Session) async {
        var allSessions = boxData.sessions
        if let idx = allSessions.firstIndex(where: { $0.id == session.id }) {
            allSessions[idx] = session
        }
        do {
            let boxdata = try await ApiRequest.saveSessions(allSessions)
            await updateBoxData(boxdata)
        } catch {
            print("Error updating session: \(error)")
        }
    }

    func useAppSession(sessionId: String, appId: String) async {
        guard let session = boxData.sessions.first(where: { $0.id == sessionId }) else { return }
        var datas = session.datas
        let curSessionsData = SessionData(key: "chavy_boxjs_cur_sessions", val: AnyCodable("{}"))
        datas.append(curSessionsData)
        do {
            let boxdata = try await ApiRequest.useAppSession(datas: datas, appId: appId)
            await updateBoxData(boxdata)
        } catch {
            print("Error using session: \(error)")
        }
    }

    func linkAppSession(sessionId: String, appId: String) async {
        guard let session = boxData.sessions.first(where: { $0.id == sessionId }) else { return }
        var curSessions = boxData.curSessions ?? [:]
        curSessions[appId] = sessionId
        let encoder = JSONEncoder()
        let curSessionsJSON = (try? encoder.encode(curSessions)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        var datas = session.datas
        datas.append(SessionData(key: "chavy_boxjs_cur_sessions", val: AnyCodable(curSessionsJSON)))
        do {
            let boxdata = try await ApiRequest.linkAppSession(datas: datas)
            await updateBoxData(boxdata)
        } catch {
            print("Error linking session: \(error)")
        }
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
