//
//  AppSubCacheModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import Foundation

struct AppSubCache: Decodable {
    let id: String
    let name: String
    let icon: String
    let author: String
    let repo: String
    let updateTime: String
    let apps: [SysApp]
}
