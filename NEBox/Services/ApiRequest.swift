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
    enum EndPoint {
        static let boxdata = "https://boxjs.com/query/boxdata"
        static let update = "https://boxjs.com/api/update"
        static let reload = "https://boxjs.com/api/reloadAppSub"
        static let addAppSub = "https://boxjs.com/api/addAppSub"
        static let deleteAppSub = "https://boxjs.com/api/deleteAppSub"
        static let runScript = "https://boxjs.com/api/runScript"
    }

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
        let resp: BoxDataResp = try await request(EndPoint.boxdata)
        return resp
    }
    
    static func updateData(path: String, data: Any) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(EndPoint.update, method: .post, parameters: ["path": path, "val": data], encoding: JSONEncoding.default)
        return resp
    }
    
    static func reloadAppSub(url: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(EndPoint.reload, method: .post, parameters: ["url": url], encoding: JSONEncoding.default)
        return resp
    }

    static func addAppSub(url: String) async throws -> BoxDataResp {
        let parameters = ["url": url, "enable": true, "id": UUID().uuidString] as [String : Any]
        let resp: BoxDataResp = try await request(EndPoint.addAppSub, method: .post, parameters: parameters, encoding: JSONEncoding.default)
        return resp
    }

    static func deleteAppSub(url: String) async throws -> BoxDataResp {
        let resp: BoxDataResp = try await request(EndPoint.deleteAppSub, method: .post, parameters: ["url": url], encoding: JSONEncoding.default)
        return resp
    }
    
    static func runScript(url: String) async throws -> ScriptResp {
        let resp: ScriptResp = try await request(EndPoint.runScript, method: .post, parameters: ["url": url, "isRemote": true], encoding: JSONEncoding.default)
        return resp
    }
}
