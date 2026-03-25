//
//  BoxJSAPI.swift
//  NEBox
//

import Foundation
import Moya
import Alamofire
import AnyCodable

enum BoxJSAPI {
    // MARK: - Queries
    case getBoxData
    case queryData(key: String)
    case getVersions
    case loadGlobalBak(id: String)

    // MARK: - Mutations (dict body)
    case updateData(path: String, val: Any)
    case reloadAppSub(url: String)
    case reloadAllAppSub
    case addAppSub(url: String, id: String)
    case deleteAppSub(url: String)
    case runScript(url: String)
    case runTxtScript(script: String)
    case saveDataKV(key: String, val: String)
    case saveGlobalBak(bak: [String: Any])
    case impGlobalBak(bak: [String: Any])
    case delGlobalBak(id: String)
    case revertGlobalBak(id: String)
    case updateGlobalBak(id: String, name: String)

    // MARK: - Array body
    case saveData(params: [SessionData])
    case useAppSession(datas: [SessionData], appId: String)
    case linkAppSession(datas: [SessionData])
}

extension BoxJSAPI: TargetType {

    var baseURL: URL {
        URL(string: ApiManager.shared.baseURL) ?? URL(string: "http://boxjs.com")!
    }

    var path: String {
        switch self {
        case .getBoxData:
            return "/query/boxdata"
        case .queryData(let key):
            let encoded = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
            return "/query/data/\(encoded)"
        case .getVersions:
            return "/query/versions"
        case .loadGlobalBak(let id):
            let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            return "/query/baks/\(encoded)"
        case .updateData:
            return "/api/update"
        case .reloadAppSub, .reloadAllAppSub:
            return "/api/reloadAppSub"
        case .addAppSub:
            return "/api/addAppSub"
        case .deleteAppSub:
            return "/api/deleteAppSub"
        case .runScript, .runTxtScript:
            return "/api/runScript"
        case .saveDataKV:
            return "/api/saveData"
        case .saveGlobalBak:
            return "/api/saveGlobalBak"
        case .impGlobalBak:
            return "/api/impGlobalBak"
        case .delGlobalBak:
            return "/api/delGlobalBak"
        case .revertGlobalBak:
            return "/api/revertGlobalBak"
        case .updateGlobalBak:
            return "/api/updateGlobalBak"
        case .saveData, .linkAppSession:
            return "/api/save"
        case .useAppSession:
            return "/api/save"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getBoxData, .queryData, .getVersions, .loadGlobalBak:
            return .get
        default:
            return .post
        }
    }

    var task: Task {
        switch self {
        // GET — no parameters
        case .getBoxData, .queryData, .getVersions, .loadGlobalBak:
            return .requestPlain

        // POST — dict body
        case .updateData(let path, let val):
            return .requestParameters(parameters: ["path": path, "val": val], encoding: JSONEncoding.default)

        case .reloadAllAppSub:
            return .requestPlain

        case .reloadAppSub(let url):
            return .requestParameters(parameters: ["url": url], encoding: JSONEncoding.default)

        case .addAppSub(let url, let id):
            return .requestParameters(parameters: ["url": url, "enable": true, "id": id], encoding: JSONEncoding.default)

        case .deleteAppSub(let url):
            return .requestParameters(parameters: ["url": url], encoding: JSONEncoding.default)

        case .runScript(let url):
            return .requestParameters(parameters: ["url": url, "isRemote": true], encoding: JSONEncoding.default)

        case .runTxtScript(let script):
            return .requestParameters(parameters: ["script": script], encoding: JSONEncoding.default)

        case .saveDataKV(let key, let val):
            return .requestParameters(parameters: ["key": key, "val": val], encoding: JSONEncoding.default)

        case .saveGlobalBak(let bak):
            return .requestParameters(parameters: bak, encoding: JSONEncoding.default)

        case .impGlobalBak(let bak):
            return .requestParameters(parameters: bak, encoding: JSONEncoding.default)

        case .delGlobalBak(let id):
            return .requestParameters(parameters: ["id": id], encoding: JSONEncoding.default)

        case .revertGlobalBak(let id):
            return .requestParameters(parameters: ["id": id], encoding: JSONEncoding.default)

        case .updateGlobalBak(let id, let name):
            return .requestParameters(parameters: ["id": id, "name": name], encoding: JSONEncoding.default)

        // POST — array body
        case .saveData(let params):
            return .requestCustomJSONEncodable(params, encoder: JSONEncoder())

        case .linkAppSession(let datas):
            return .requestCustomJSONEncodable(datas, encoder: JSONEncoder())

        // POST — array body + query param
        case .useAppSession(let datas, let appId):
            let bodyData = (try? JSONEncoder().encode(datas)) ?? Data()
            let encoded = appId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appId
            return .requestCompositeData(bodyData: bodyData, urlParameters: ["appid": encoded])
        }
    }

    var headers: [String: String]? {
        switch method {
        case .post:
            return ["Content-Type": "application/json"]
        default:
            return nil
        }
    }
}
