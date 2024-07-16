//
//  BoxDataModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import Foundation
import AnyCodable

struct BoxDataModel: Decodable {
    let appSubCaches: [String: AppSubCache]
    let datas: [String: AnyCodable?]
    let usercfgs: UserConfig
    let sysapps: [SysApp]
}
