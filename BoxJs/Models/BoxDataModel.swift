//
//  BoxDataModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import AnyCodable
import Foundation

struct AppSubCache: Codable {
    let id: String
    var name: String
    let icon: String
    var author: String
    var repo: String
    let updateTime: String
    var apps: [AppModel]
    
    // AppSub Struct
    var isErr: Bool?
    var enable: Bool?
    var url: String?
    var raw: AppSub?
}

extension AppSubCache {
    var isValid: Bool {
        return !apps.isEmpty && apps.allSatisfy { !$0.id.isEmpty }
    }
}

struct AppModel: Codable {
    var id: String
    let name: String
    let author: String
    let repo: String?
    let descs: [String]?
    let keys: [String]?
    var icons: [String]
    let desc: String?
    let script: String?
    let descs_html: [String]?
    // let settings: [Setting] 暂时不管
    
    
    var favIcon: String?
    var icon: String?
    var favIconColor: String?
    
}

extension AppModel {
    func withIcon(_ icons: [String], _ icon: String, _ favIcon: String, _ favIconColor: String) -> AppModel {
        var newApp = self
        newApp.icons = icons
        newApp.icon = icon
        newApp.favIcon = favIcon
        newApp.favIconColor = favIconColor
        
        return newApp
    }
}

struct UserConfig: Codable {
    let appsubs: [AppSub]
    let favapps: [String]
}

struct AppSub: Codable {
    let enable: Bool
    let id: String?
    let url: String
    
    // MARK: 非接口返回
    var isErr: Bool?
}


struct BodxDataResp: Codable {
    let appSubCaches: [String: AppSubCache]
//    let datas: [String: AnyCodable?]
    let usercfgs: UserConfig?
    let sysapps: [AppModel]
    
    var appsubs: [AppSub] {
        return usercfgs?.appsubs ?? []
    }
    
    var displayAppSubCaches: [String: AppSubCache] {
        var ids = [String]()
        for appSub in appsubs {
            // 查找 appSubCaches 中对应的缓存
            if let sub = appSubCaches[appSub.url], !(appSub.isErr ?? false) {
                // 判断 sub 是否存在，sub.apps 是否是数组，!appsub.isErr
                if !sub.apps.isEmpty {
                    ids.append(contentsOf: sub.apps.map { $0.id })
                }
            }
        }
        
        let replyIds = ids.enumerated().compactMap { index, value in
            ids[(index + 1)...].contains(value) ? value : nil
        }
        
        var updatedAppSubCaches = appSubCaches
        
        for appSub in appsubs {
            if var sub = updatedAppSubCaches[appSub.url], !(appSub.isErr ?? false) {
                if !sub.apps.isEmpty {
                    let updatedApps = sub.apps.map { app in
                        var cloneApp = app
                        if replyIds.contains(app.id) {
                            cloneApp.id = "\(app.author)_\(app.id)"
                        }
                        return cloneApp
                    }
                    sub.apps = updatedApps
                    updatedAppSubCaches[appSub.url] = sub
                }
            }
        }
        return updatedAppSubCaches
    }
    
    var displayAppSubs: [AppSubCache] {
        return appsubs.map { sub in
            let cacheSub = appSubCaches[sub.url]
            let name = cacheSub?.name ?? "匿名订阅"
            let author = cacheSub?.author ?? "@anonymous"
            let repo = cacheSub?.repo ?? sub.url
            let isErr = cacheSub?.isValid == true ? sub.isErr : true
            
            return AppSubCache(
                id: (cacheSub?.id ?? sub.id) ?? "",
                name: name,
                icon: cacheSub?.icon ?? "",
                author: author,
                repo: repo,
                updateTime: cacheSub?.updateTime ?? "",
                apps: cacheSub?.isValid == true ? (cacheSub?.apps ?? []) : [],
                isErr: isErr,
                enable: cacheSub?.enable ?? sub.enable,
                url: sub.url,
                raw: sub
            )
        }
    }
    
    var displaySubApps: [AppModel] {
        var apps: [AppModel] = []
        for appSub in displayAppSubs {
            if let sub = displayAppSubCaches[appSub.url!], !(appSub.isErr ?? false) {
                for app in sub.apps {
                    apps.append(loadAppBaseInfo(app))
                }
            }
        }
        
        return apps
    }
    
    func loadAppBaseInfo(_ app: AppModel) -> AppModel {
        var icons = app.icons.isEmpty ? ["https://raw.githubusercontent.com/Orz-3/mini/master/Alpha/appstore.png", "https://raw.githubusercontent.com/Orz-3/mini/master/Color/appstore.png"] : app.icons

        if app.icons.first(where: { $0.contains("/Orz-3/task/master/") }) != nil {
            icons[0] = app.icons[0].replacingOccurrences(of: "/Orz-3/mini/master/", with: "/Orz-3/mini/master/Alpha/")
            icons[1] = app.icons[1].replacingOccurrences(of: "/Orz-3/task/master/", with: "/Orz-3/mini/master/Color/")
        }
        let isFav = self.usercfgs?.favapps.contains(app.id) ?? false
        
        let newApp = app.withIcon(icons, icons[0], isFav ? "mdi-star" : "mdi-star-outline", isFav ? "primary" : "grey")
        return newApp
    }
}

