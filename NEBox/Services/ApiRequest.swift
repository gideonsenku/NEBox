//
//  ApiRequest.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import Alamofire
import AnyCodable
import Foundation
import SwiftyJSON

enum RequestError: Error {
    case networkFail
    case statusFail(code: Int, message: String)
    case decodeFail(message: String)
}

enum ApiRequest {
    private static var base: String { ApiManager.shared.baseURL }

    enum Path {
        static let boxdata = "/query/boxdata"
        static let update = "/api/update"
        static let reload = "/api/reloadAppSub"
        static let addAppSub = "/api/addAppSub"
        static let deleteAppSub = "/api/deleteAppSub"
        static let runScript = "/api/runScript"
        static let saveData = "/api/save"
        static let queryData = "/query/data"
        static let saveGlobalBak = "/api/saveGlobalBak"
        static let impGlobalBak = "/api/impGlobalBak"
        static let delGlobalBak = "/api/delGlobalBak"
        static let revertGlobalBak = "/api/revertGlobalBak"
        static let updateGlobalBak = "/api/updateGlobalBak"
        static let queryBaks = "/query/baks"
        static let queryVersions = "/query/versions"
        static let saveDataKV = "/api/saveData"
    }

    private static func endpoint(_ path: String) -> String { base + path }

    static func requestJSON(_ url: URLConvertible,
                            method: HTTPMethod = .get,
                            parameters: Parameters = [:],
                            encoding: ParameterEncoding = URLEncoding.default,
                            complete: ((Result<JSON, RequestError>) -> Void)? = nil)
    {
        AF.request(url, method: method, parameters: parameters, encoding: encoding).responseData { response in
            switch response.result {
            case let .success(data):
                let json = JSON(data)
//                print(json)
                let errorCode = json["code"].intValue
                if errorCode != 0 {
                    let message = json["message"].stringValue
                    print(errorCode, message)
                    complete?(.failure(.statusFail(code: errorCode, message: message)))
                    return
                }
                complete?(.success(json))
            case let .failure(err):
                print(err)
                complete?(.failure(.networkFail))
            }
        }
    }

    static func request<T: Decodable>(_ url: URLConvertible,
                                      method: HTTPMethod = .get,
                                      parameters: Parameters = [:],
                                      auth _: Bool = true,
                                      encoding: ParameterEncoding = URLEncoding.default,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      complete: ((Result<T, RequestError>) -> Void)?)
    {
        requestJSON(url, method: method, parameters: parameters, encoding: encoding) { result in
            switch result {
            case let .success(data):
                do {
                    let data = try data.rawData()
                    let object = try decoder.decode(T.self, from: data)
                    complete?(.success(object))
                } catch let err {
                    print(err)
                    complete?(.failure(.decodeFail(message: err.localizedDescription + String(describing: err))))
                }
            case let .failure(err):
                complete?(.failure(err))
            }
        }
    }

    static func request<T: Decodable>(_ url: URLConvertible,
                                      method: HTTPMethod = .get,
                                      parameters: Parameters = [:],
                                      encoding: ParameterEncoding = URLEncoding.default,
                                      decoder: JSONDecoder = JSONDecoder()) async throws -> T
    {
        try await withCheckedThrowingContinuation { configure in
            request(url, method: method, parameters: parameters, encoding: encoding, decoder: decoder) { resp in
                configure.resume(with: resp)
            }
        }
    }

    static func getBoxData(lastIdx _: Int = 0) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.boxdata))
        return resp
    }
    
    static func updateData(path: String, data: Any) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.update), method: .post, parameters: ["path": path, "val": data], encoding: JSONEncoding.default)
        return resp
    }
    
    static func reloadAppSub(url: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.reload), method: .post, parameters: ["url": url], encoding: JSONEncoding.default)
        return resp
    }

    static func addAppSub(url: String) async throws -> BoxDataResp {
        let parameters = ["url": url, "enable": true, "id": UUID().uuidString] as [String : Any]
        let resp: BoxDataResp = try await request(endpoint(Path.addAppSub), method: .post, parameters: parameters, encoding: JSONEncoding.default)
        return resp
    }

    static func deleteAppSub(url: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.deleteAppSub), method: .post, parameters: ["url": url], encoding: JSONEncoding.default)
        return resp
    }
    
    static func runScript(url: String) async throws -> ScriptResp {
        let resp: ScriptResp = try await request(endpoint(Path.runScript), method: .post, parameters: ["url": url, "isRemote": true], encoding: JSONEncoding.default)
        return resp
    }

    static func runTxtScript(script: String) async throws -> ScriptResp {
        let resp: ScriptResp = try await request(endpoint(Path.runScript), method: .post, parameters: ["script": script], encoding: JSONEncoding.default)
        return resp
    }

    static func getVersions() async throws -> VersionsResp {
        let resp: VersionsResp = try await request(endpoint(Path.queryVersions))
        return resp
    }

    static func saveData(parameters: [SessionData]) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await AF.request(endpoint(Path.saveData), method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
            .serializingDecodable(BoxDataResp.self)
            .value
        return resp
    }

    // MARK: - 数据查看器

    static func queryData(key: String) async throws -> DataQueryResp {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let resp: DataQueryResp = try await request(endpoint(Path.queryData) + "/\(encodedKey)")
        return resp
    }

    static func saveDataKV(key: String, val: String) async throws -> DataQueryResp {
        let resp: DataQueryResp = try await request(endpoint(Path.saveDataKV), method: .post, parameters: ["key": key, "val": val], encoding: JSONEncoding.default)
        return resp
    }

    // MARK: - 全局备份

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
        let resp: BoxDataResp = try await request(endpoint(Path.saveGlobalBak), method: .post, parameters: bak, encoding: JSONEncoding.default)
        return resp
    }

    static func delGlobalBak(id: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.delGlobalBak), method: .post, parameters: ["id": id], encoding: JSONEncoding.default)
        return resp
    }

    static func revertGlobalBak(id: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.revertGlobalBak), method: .post, parameters: ["id": id], encoding: JSONEncoding.default)
        return resp
    }

    static func updateGlobalBak(id: String, name: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(endpoint(Path.updateGlobalBak), method: .post, parameters: ["id": id, "name": name], encoding: JSONEncoding.default)
        return resp
    }

    static func impGlobalBak(bakData: String, name: String) async throws -> BoxDataResp {
        let bakJSON = try JSONSerialization.jsonObject(with: Data(bakData.utf8))
        let bak: [String: Any] = [
            "id": UUID().uuidString,
            "name": name,
            "createTime": ISO8601DateFormatter().string(from: Date()),
            "bak": bakJSON
        ]
        let resp: BoxDataResp = try await request(endpoint(Path.impGlobalBak), method: .post, parameters: bak, encoding: JSONEncoding.default)
        return resp
    }

    static func loadGlobalBak(id: String) async throws -> AnyCodable {
        let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        let resp: AnyCodable = try await request(endpoint(Path.queryBaks) + "/\(encodedId)")
        return resp
    }

    // MARK: - 会话管理

    static func saveSessions(_ sessions: [Session]) async throws -> BoxDataResp {
        let key = "chavy_boxjs_sessions"
        let encoder = JSONEncoder()
        let data = try encoder.encode(sessions)
        let val = String(data: data, encoding: .utf8) ?? "[]"
        let parameters = [SessionData(key: key, val: AnyCodable(val))]
        let resp: BoxDataResp = try await AF.request(endpoint(Path.saveData), method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
            .serializingDecodable(BoxDataResp.self)
            .value
        return resp
    }

    static func useAppSession(datas: [SessionData], appId: String) async throws -> BoxDataResp {
        let encodedAppId = appId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appId
        let resp: BoxDataResp = try await AF.request("\(endpoint(Path.saveData))?appid=\(encodedAppId)", method: .post, parameters: datas, encoder: JSONParameterEncoder.default)
            .serializingDecodable(BoxDataResp.self)
            .value
        return resp
    }

    static func linkAppSession(datas: [SessionData]) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await AF.request(endpoint(Path.saveData), method: .post, parameters: datas, encoder: JSONParameterEncoder.default)
            .serializingDecodable(BoxDataResp.self)
            .value
        return resp
    }
}
