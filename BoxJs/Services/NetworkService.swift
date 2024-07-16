//
//  request.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import Foundation
import Alamofire
import AnyCodable

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func getBoxData() async throws -> BoxDataModel {
        let url = "https://boxjs.com/query/boxdata"
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url).validate().responseDecodable(of: BoxDataModel.self) { response in
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

