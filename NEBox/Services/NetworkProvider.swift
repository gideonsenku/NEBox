//
//  NetworkProvider.swift
//  NEBox
//

import Foundation
import Moya
import os.log

private let netLog = Logger(subsystem: "NEBox", category: "Network")

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
                netLog.error("Decode failed for \(String(describing: T.self)). Raw response: \(raw.prefix(500))")
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
        let response: Response
        do {
            response = try await shared.request(target)
        } catch {
            throw RequestError.networkFail
        }
        return try response.mapBoxJS(T.self)
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
