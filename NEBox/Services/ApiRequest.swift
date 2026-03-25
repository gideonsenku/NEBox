//
//  ApiRequest.swift
//  NEBox
//
//  Created by Senku on 7/12/24.
//

import AnyCodable
import Foundation

enum RequestError: Error {
    case networkFail
    case statusFail(code: Int, message: String)
    case decodeFail(message: String)
}

enum ApiRequest {

    // MARK: - Queries

    static func getBoxData(lastIdx _: Int = 0) async throws -> BoxDataResp {
        try await NetworkProvider.request(.getBoxData)
    }

    static func getVersions() async throws -> VersionsResp {
        try await NetworkProvider.request(.getVersions)
    }

    static func queryData(key: String) async throws -> DataQueryResp {
        try await NetworkProvider.request(.queryData(key: key))
    }

    static func loadGlobalBak(id: String) async throws -> AnyCodable {
        try await NetworkProvider.request(.loadGlobalBak(id: id))
    }

    // MARK: - Data Mutations

    static func updateData(path: String, data: Any) async throws -> BoxDataResp {
        try await NetworkProvider.request(.updateData(path: path, val: data))
    }

    static func saveDataKV(key: String, val: String) async throws -> DataQueryResp {
        try await NetworkProvider.request(.saveDataKV(key: key, val: val))
    }

    // MARK: - Subscriptions

    static func reloadAppSub(url: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.reloadAppSub(url: url))
    }

    static func reloadAllAppSub() async throws -> BoxDataResp {
        try await NetworkProvider.request(.reloadAllAppSub)
    }

    static func addAppSub(url: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.addAppSub(url: url, id: UUID().uuidString))
    }

    static func deleteAppSub(url: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.deleteAppSub(url: url))
    }

    // MARK: - Scripts

    static func runScript(url: String) async throws -> ScriptResp {
        try await NetworkProvider.request(.runScript(url: url))
    }

    static func runTxtScript(script: String) async throws -> ScriptResp {
        try await NetworkProvider.request(.runTxtScript(script: script))
    }

    // MARK: - Session / Save Data

    static func saveData(parameters: [SessionData]) async throws -> BoxDataResp {
        try await NetworkProvider.request(.saveData(params: parameters))
    }

    static func saveSessions(_ sessions: [Session]) async throws -> BoxDataResp {
        let key = "chavy_boxjs_sessions"
        let data = try JSONEncoder().encode(sessions)
        let val = String(data: data, encoding: .utf8) ?? "[]"
        let parameters = [SessionData(key: key, val: AnyCodable(val))]
        return try await NetworkProvider.request(.saveData(params: parameters))
    }

    static func useAppSession(datas: [SessionData], appId: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.useAppSession(datas: datas, appId: appId))
    }

    static func linkAppSession(datas: [SessionData]) async throws -> BoxDataResp {
        try await NetworkProvider.request(.linkAppSession(datas: datas))
    }

    // MARK: - Global Backups

    static func saveGlobalBak(name: String, env: String, version: String, versionType: String) async throws -> BoxDataResp {
        let bak: [String: Any] = [
            "id": UUID().uuidString,
            "name": name,
            "env": env,
            "version": version,
            "versionType": versionType,
            "createTime": ISO8601DateFormatter().string(from: Date()),
            "tags": [env, version, versionType]
        ]
        return try await NetworkProvider.request(.saveGlobalBak(bak: bak))
    }

    static func delGlobalBak(id: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.delGlobalBak(id: id))
    }

    static func revertGlobalBak(id: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.revertGlobalBak(id: id))
    }

    static func updateGlobalBak(id: String, name: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.updateGlobalBak(id: id, name: name))
    }

    static func impGlobalBak(bakData: String, name: String) async throws -> BoxDataResp {
        let bakJSON = try JSONSerialization.jsonObject(with: Data(bakData.utf8))
        let bak: [String: Any] = [
            "id": UUID().uuidString,
            "name": name,
            "createTime": ISO8601DateFormatter().string(from: Date()),
            "bak": bakJSON
        ]
        return try await NetworkProvider.request(.impGlobalBak(bak: bak))
    }
}
