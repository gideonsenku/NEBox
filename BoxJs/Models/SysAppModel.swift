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
    let icons: [String]
    let desc: String?
    let script: String?
    let descs_html: [String]?
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
