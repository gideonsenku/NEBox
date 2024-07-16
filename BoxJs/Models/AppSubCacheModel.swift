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

extension AppSubCache {
    var isValid: Bool {
        return !apps.isEmpty && apps.allSatisfy { !$0.id.isEmpty }
    }

    func withApps(_ updatedApps: [SysApp]) -> AppSubCache {
        return AppSubCache(
            id: self.id,
            name: self.name,
            icon: self.icon,
            author: self.author,
            repo: self.repo,
            updateTime: self.updateTime,
            apps: updatedApps
        )
    }
}

