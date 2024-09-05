//
//  BoxDataModel.swift
//  BoxJs
//
//  Created by Senku on 7/16/24.
//

import AnyCodable
import Foundation

struct AppSubCache: Codable, Identifiable {
    let id: String
    var name: String
    let icon: String
    var author: String
    var repo: String
    var updateTime: String
    var apps: [AppModel]
    
    // AppSub Struct
    var isErr: Bool?
    var enable: Bool?
    var url: String?
    var raw: AppSub?
    
    var formatTime: String {
        return formattedTimeDifference(from: self.updateTime)
    }
    
    func formattedTimeDifference(from isoDateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: isoDateString) else {
            return "Invalid date"
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let components = calendar.dateComponents([.minute, .hour], from: date, to: now)

            if let hours = components.hour, hours > 0 {
                return "\(hours)小时前"
            } else if let minutes = components.minute, minutes > 0 {
                return "\(minutes)分钟前"
            } else {
                return "刚刚"
            }
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd"
            return dateFormatter.string(from: date)
        }
    }
}

extension AppSubCache {
    var isValid: Bool {
        return !apps.isEmpty && apps.allSatisfy { !$0.id.isEmpty }
    }
}

struct RunScript: Codable {
    var name: String
    var script: String
}

struct RadioItem: Codable {
    let key: String
    let label: String
}

struct Setting: Codable {
    let id: String
    let name: String?
    var val: AnyCodable?
    let desc: String?
    let placeholder: String?
    let type: String?
    let items: [RadioItem]?
}

struct AppModel: Codable, Identifiable {
    var id: String
    let name: String
    let author: String
    let repo: String?
    let descs: [String]?
    let keys: [String]?
    var icons: [String]
    let desc: String?
    let script: String?
    let scripts: [RunScript]?

    let desc_html: String?
    let descs_html: [String]?
    var settings: [Setting]?
    
    var favIcon: String?
    var icon: String?
    var favIconColor: String?
    var isFav: Bool?
    var hasDescription: Bool {
        return (desc != nil && !desc!.isEmpty) ||
               (descs != nil && !descs!.isEmpty) ||
               (desc_html != nil && !desc_html!.isEmpty) ||
               (descs_html != nil && !descs_html!.isEmpty)
    }
}

extension AppModel {
    func withIcon(_ icons: [String], _ icon: String, isFav: Bool) -> AppModel {
        var newApp = self
        newApp.icons = icons
        newApp.icon = icon
        newApp.isFav = isFav
        
        return newApp
    }
}

struct UserConfig: Codable {
    let appsubs: [AppSub]
    let favapps: [String]
    let bgimgs: String?
    let bgimg: String?
}

struct AppSub: Codable {
    let enable: Bool
    let id: String?
    let url: String
    
    // MARK: 非接口返回
    
    var isErr: Bool?
}

struct SessionData: Codable {
    let key: String
    let val: AnyCodable?
}

struct Session: Codable {
    let id: String
    let name: String
    let enable: Bool
    let appId: String
    let appName: String
    let createTime: String
    let datas: [SessionData]
}

struct BoxDataResp: Codable {
    let appSubCaches: [String: AppSubCache]
    let datas: [String: AnyCodable?]
    let sessions: [Session]
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
            
            let cacheApps = cacheSub?.isValid == true ? (cacheSub?.apps ?? []) : []
            
            return AppSubCache(
                id: (cacheSub?.id ?? sub.id) ?? "",
                name: name,
                icon: cacheSub?.icon ?? "",
                author: author,
                repo: repo,
                updateTime: cacheSub?.updateTime ?? "",
                apps: cacheApps.map { app in
                    loadAppBaseInfo(app)
                },
                isErr: isErr,
                enable: cacheSub?.enable ?? sub.enable,
                url: sub.url,
                raw: sub
            )
        }
    }
    
    var displaySysApps: [AppModel] {
        return sysapps.map { app in
            loadAppBaseInfo(app)
        }
    }
    
    var apps: [AppModel] {
        return displayAppSubs.flatMap { sub in
            let apps = displayAppSubCaches[sub.url!]?.apps ?? []
            return apps.map { app in
                loadAppBaseInfo(app)
            }
        } + displaySysApps
    }
    var favApps: [AppModel] {
        var favapps: [AppModel] = []
        if let favAppIds = usercfgs?.favapps, !favAppIds.isEmpty {
            for favId in favAppIds {
                if let app = apps.first(where: { $0.id == favId }) {
                    favapps.append(app)
                }
            }
        }
        return favapps
    }
    
    var bgImgUrl: String {
        let imgGroup = usercfgs?.bgimgs?.split(separator: "\n")
        let imgStr = usercfgs?.bgimg
        return "https://64.media.tumblr.com/451bca19ad0b695c08b54b4287e4f935/tumblr_nb70h5f6XN1rnbw6mo2_r1_1280.gifv"
    }
    
    func loadAppBaseInfo(_ app: AppModel) -> AppModel {
        var icons = app.icons.isEmpty ? ["https://raw.githubusercontent.com/Orz-3/mini/master/Alpha/appstore.png", "https://raw.githubusercontent.com/Orz-3/mini/master/Color/appstore.png"] : app.icons
        
        if app.icons.first(where: { $0.contains("/Orz-3/task/master/") }) != nil {
            icons[0] = app.icons[0].replacingOccurrences(of: "/Orz-3/mini/master/", with: "/Orz-3/mini/master/Alpha/")
            icons[1] = app.icons[1].replacingOccurrences(of: "/Orz-3/task/master/", with: "/Orz-3/mini/master/Color/")
        }
        let isFav = usercfgs?.favapps.contains(app.id) ?? false
        
        let newApp = app.withIcon(icons, icons.last ?? icons[0], isFav: isFav)
        return newApp
    }
}


struct ScriptResp: Codable {
    var exception: String?
    var output: String?
}
