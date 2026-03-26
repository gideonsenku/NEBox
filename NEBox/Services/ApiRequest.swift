//
//  ApiRequest.swift
//  NEBox
//
//  Created by Senku on 7/12/24.
//

import AnyCodable
import Foundation

/// High-level API helpers that contain business logic (parameter assembly, encoding).
/// For simple pass-through calls, use `NetworkProvider.request(.endpoint)` directly.
enum ApiRequest {

    // MARK: - Subscriptions

    static func addAppSub(url: String) async throws -> BoxDataResp {
        try await NetworkProvider.request(.addAppSub(url: url, id: UUID().uuidString))
    }

    // MARK: - Sessions

    static func saveSessions(_ sessions: [Session]) async throws -> BoxDataResp {
        let key = "chavy_boxjs_sessions"
        let data = try JSONEncoder().encode(sessions)
        let val = String(data: data, encoding: .utf8) ?? "[]"
        let parameters = [SessionData(key: key, val: AnyCodable(val))]
        return try await NetworkProvider.request(.saveData(params: parameters))
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
