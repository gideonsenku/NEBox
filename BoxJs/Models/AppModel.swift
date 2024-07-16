//
//  AppModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import Foundation

struct AppModel {
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
    let descs: [String]?
    let keys: [String]?
    let settings: [Setting]?
    let scripts: [Script]?
    let icons: [String]
    let desc: String?
    let script: String?
    let descs_html: [String]?
}
