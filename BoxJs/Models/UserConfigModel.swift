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
    var id: String?
    var url: String
    var enable: Bool
    var isErr: Bool?
    var name: String?
    var icon: String?
    var author: String?
    var repo: String?
    var updateTime: String?
    var apps: [SysApp]?
}

extension AppSub {
    func merged(with cache: AppSubCache) -> AppSub {
        var newSub = self
        newSub.id = cache.id
        newSub.name = cache.name
        newSub.icon = cache.icon
        newSub.author = cache.author
        newSub.repo = cache.repo
        newSub.updateTime = cache.updateTime
        newSub.apps = cache.apps
        return newSub
    }
}

