//
//  NetworkProvider.swift
//  NEBox
//

import Foundation
import Moya

// MARK: - Request Error

enum RequestError: Error {
    case networkFail
    case statusFail(code: Int, message: String)
    case decodeFail(message: String)
}

extension RequestError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkFail: return "网络连接失败"
        case .statusFail(_, let message): return message
        case .decodeFail(let message): return "数据解析失败: \(message)"
        }
    }
}

// MARK: - Response Envelope

/// Matches the BoxJS response envelope: { "code": 0, "message": "..." }
private struct APIEnvelope: Decodable {
    let code: Int
    let message: String?
}

// MARK: - Response Mapping

extension Response {
    /// Validates the BoxJS `code` field, then decodes the full body as T.
    func mapBoxJS<T: Decodable>(_ type: T.Type,
                                decoder: JSONDecoder = JSONDecoder()) throws -> T {
        // 1. Check HTTP status
        let filtered = try filterSuccessfulStatusCodes()

        // 2. Decode envelope to check business error code
        if let envelope = try? JSONDecoder().decode(APIEnvelope.self, from: filtered.data) {
            guard envelope.code == 0 else {
                appLog(.error, category: .network, "BoxJS business code failed: code=\(envelope.code), message=\(envelope.message ?? "nil")")
                throw RequestError.statusFail(
                    code: envelope.code,
                    message: envelope.message ?? "Unknown error"
                )
            }
        }

        // 3. Decode full response
        do {
            return try decoder.decode(T.self, from: filtered.data)
        } catch {
            if let raw = String(data: filtered.data, encoding: .utf8) {
                appLog(.error, category: .network, "Decode failed for \(String(describing: T.self)). Raw: \(raw.prefix(500))")
            }
            throw RequestError.decodeFail(
                message: error.localizedDescription + String(describing: error)
            )
        }
    }
}

// MARK: - Provider

enum NetworkProvider {
    static let shared = MoyaProvider<BoxJSAPI>()

    /// Generic async request with BoxJS envelope validation.
    static func request<T: Decodable>(_ target: BoxJSAPI) async throws -> T {
        let fullURL = "\(ApiManager.shared.baseURL)\(target.path)"
        appLog(.info, category: .network, "→ \(target.method.rawValue) \(fullURL)")
        let response: Response
        do {
            response = try await shared.request(target)
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            appLog(.error, category: .network, "✗ \(fullURL) network fail: \(msg)")
            throw RequestError.networkFail
        }
        appLog(.info, category: .network, "← \(fullURL) \(response.statusCode)")
        do {
            return try response.mapBoxJS(T.self)
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            appLog(.error, category: .network, "✗ \(fullURL) map/decode fail: \(msg)")
            throw error
        }
    }
}

// MARK: - MoyaProvider async extension

extension MoyaProvider {
    func request(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
