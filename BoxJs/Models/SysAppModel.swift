//
//  SysAppModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import Foundation
import AnyCodable

// 定义 SysApp 结构体
struct SysApp: Decodable {
    let id: String
    let name: String?
    let descs: [String]?
    let keys: [String]?
    let settings: [Setting]?
    let scripts: [Script]?
    let author: String
    let repo: String?
    var icons: [String]
    let desc: String?
    let script: String?
    let descs_html: [String]?
    let favIcon: String?
    let favIconColor: String?
    let icon: String?
    
    mutating func updateIcon(at index: Int, of oldPath: String, with newPath: String) {
        guard index >= 0 && index < icons.count else { return }
        icons[index] = icons[index].replacingOccurrences(of: oldPath, with: newPath)
    }
}

extension SysApp {
    func withId(_ newId: String) -> SysApp {
        return SysApp(
            id: newId,
            name: self.name,
            descs: self.descs,
            keys: self.keys,
            settings: self.settings,
            scripts: self.scripts,
            author: self.author,
            repo: self.repo,
            icons: self.icons,
            desc: self.desc,
            script: self.script,
            descs_html: self.descs_html,
            favIcon: self.favIcon,
            favIconColor: self.favIcon,
            icon: self.icon
        )
    }
    
    func withIcon (_ icons: [String], _ icon: String, _ favIcon: String, _ favIconColor: String) -> SysApp {
        return SysApp(
            id: self.id,
            name: self.name,
            descs: self.descs,
            keys: self.keys,
            settings: self.settings,
            scripts: self.scripts,
            author: self.author,
            repo: self.repo,
            icons: icons,
            desc: self.desc,
            script: self.script,
            descs_html: self.descs_html,
            favIcon: favIcon,
            favIconColor: favIconColor,
            icon: icon

        )
    }
}

struct Setting: Decodable {
    let id: String
    let name: String?
    let val: AnyCodable?
    let type: String?
    let placeholder: String?
    let autoGrow: Bool?
    let rows: Int?
    let persistentHint: Bool?
    let desc: String?
    let items: AnyCodable?
    let canvas: Bool?
}

// 定义 Script 结构体
struct Script: Decodable {
    let name: String
    let script: String
}
