//
//  request.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import Foundation
import Alamofire

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func getBoxData() async throws -> BoxResponse {
        let url = "https://boxjs.com/query/boxdata"
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url).validate().responseDecodable(of: BoxResponse.self) { response in
                switch response.result {
                case .success(let resp):
                    continuation.resume(returning: resp)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct AppSub: Decodable {
    let id: String?
    let url: String
    let enable: Bool
}

// 定义 Script 结构体
struct Script: Decodable {
    let name: String
    let script: String
}

// 定义 Item 结构体
struct Item: Codable {
    let key: String
    let label: String
}

enum CodableValue: Decodable {
    case string(String)
    case int(Int)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else {
            throw DecodingError.typeMismatch(CodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode CodableValue"))
        }
    }
}

// 定义一个枚举来处理可能的类型
enum ItemsEnumType: Decodable {
    case string(String)
    case array([String])
    case none
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else {
            self = .none
        }
    }
}


struct Setting: Decodable {
    let id: String
    let name: String
    let val: CodableValue?
    let type: String
    let placeholder: String?
    let autoGrow: Bool?
    let rows: Int?
    let persistentHint: Bool?
    let desc: String?
    let items: ItemsEnumType?
    let canvas: Bool?
}

// 定义 SysApp 结构体
struct SysApp: Decodable {
    let id: String
    let name: String
    let descs: [String]?
    let keys: [String]?
    let settings: [Setting]?
    let scripts: [Script]?
    let author: String
    let repo: String?
    let icons: [String]
    let desc: String?
    let script: String?
    let descs_html: [String]?
}

struct UserConfigs: Decodable {
    let favapps: [String?]
}

struct BoxResponse: Decodable {
//    let datas: [String: String?]
    let usercfgs: UserConfigs
    let sysapps: [SysApp]
}

