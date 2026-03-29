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
        try await validateSubscriptionSource(url: url)
        return try await NetworkProvider.request(.addAppSub(url: url, id: UUID().uuidString))
    }

    private static func validateSubscriptionSource(url: String) async throws {
        guard let requestURL = URL(string: url) else {
            throw RequestError.statusFail(code: -1, message: "订阅地址无效")
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RequestError.statusFail(code: -1, message: "订阅地址响应异常")
            }
            guard (200 ... 299).contains(http.statusCode) else {
                throw RequestError.statusFail(code: http.statusCode, message: "订阅地址请求失败")
            }

            let hasContent = !data.isEmpty &&
                !String(decoding: data, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            guard hasContent else {
                throw RequestError.statusFail(code: -1, message: "订阅地址暂无可用数据")
            }
        } catch let error as RequestError {
            throw error
        } catch {
            throw RequestError.networkFail
        }
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
