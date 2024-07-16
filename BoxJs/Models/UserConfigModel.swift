//
//  UserConfigModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import Foundation

struct UserConfig: Decodable {
    let favapps: [String?]
    let appsubs: [AppSub]
}

struct AppSub: Decodable {
    let id: String?
    let url: String
    let enable: Bool
}
