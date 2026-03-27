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

struct RadioItem: Codable, Identifiable {
    let key: String
    let label: String
    
    var id: String { key }
}

struct Setting: Codable {
    let id: String
    let name: String?
    var val: AnyCodable?
    let desc: String?
    let placeholder: String?
    let type: String?
    let items: [RadioItem]?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        val = try c.decodeIfPresent(AnyCodable.self, forKey: .val)
        desc = try c.decodeIfPresent(String.self, forKey: .desc)
        placeholder = try c.decodeIfPresent(String.self, forKey: .placeholder)
        type = try c.decodeIfPresent(String.self, forKey: .type)

        // items can be [RadioItem] or a "key@label\n..." string
        if let arr = try? c.decodeIfPresent([RadioItem].self, forKey: .items) {
            items = arr
        } else if let str = try? c.decodeIfPresent(String.self, forKey: .items) {
            items = str.components(separatedBy: "\n").compactMap { line in
                let parts = line.components(separatedBy: "@")
                guard parts.count >= 2 else { return nil }
                return RadioItem(key: parts[0], label: parts[1])
            }
        } else {
            items = nil
        }
    }
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        author = try c.decodeIfPresent(String.self, forKey: .author) ?? "@anonymous"
        repo = try c.decodeIfPresent(String.self, forKey: .repo)
        descs = try c.decodeIfPresent([String].self, forKey: .descs)
        keys = try c.decodeIfPresent([String].self, forKey: .keys)
        icons = try c.decode([String].self, forKey: .icons)
        desc = try c.decodeIfPresent(String.self, forKey: .desc)
        script = try c.decodeIfPresent(String.self, forKey: .script)
        scripts = try c.decodeIfPresent([RunScript].self, forKey: .scripts)
        desc_html = try c.decodeIfPresent(String.self, forKey: .desc_html)
        descs_html = try c.decodeIfPresent([String].self, forKey: .descs_html)
        settings = try c.decodeIfPresent([Setting].self, forKey: .settings)
        favIcon = try c.decodeIfPresent(String.self, forKey: .favIcon)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        favIconColor = try c.decodeIfPresent(String.self, forKey: .favIconColor)
        isFav = try c.decodeIfPresent(Bool.self, forKey: .isFav)
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
    let name: String?
    let icon: String?
    let viewkeys: [String]?
    let gist_cache_key: [String]?
    // Preferences
    let theme: String?
    let isTransparentIcons: Bool?
    let isWallpaperMode: Bool?
    let isMute: Bool?
    let isMuteQueryAlert: Bool?
    let isHideHelp: Bool?
    let isHideBoxIcon: Bool?
    let isHideMyTitle: Bool?
    let isHideCoding: Bool?
    let isHideRefresh: Bool?
    let isDebugWeb: Bool?
    let lang: String?
    /// Surge HTTP-API 地址，如 `examplekey@127.0.0.1:6166`
    let httpapi: String?
    /// 逗号分隔的候选列表；有值时 UI 用选择器，否则为自由输入
    let httpapis: String?
}

extension UserConfig {
    /// 合并覆盖（`nil` 表示保留原值），供乐观更新使用
    func with(
        appsubs: [AppSub]? = nil,
        favapps: [String]? = nil,
        bgimgs: String? = nil,
        bgimg: String? = nil,
        name: String? = nil,
        icon: String? = nil,
        viewkeys: [String]? = nil,
        gist_cache_key: [String]? = nil,
        theme: String? = nil,
        isTransparentIcons: Bool? = nil,
        isWallpaperMode: Bool? = nil,
        isMute: Bool? = nil,
        isMuteQueryAlert: Bool? = nil,
        isHideHelp: Bool? = nil,
        isHideBoxIcon: Bool? = nil,
        isHideMyTitle: Bool? = nil,
        isHideCoding: Bool? = nil,
        isHideRefresh: Bool? = nil,
        isDebugWeb: Bool? = nil,
        lang: String? = nil,
        httpapi: String? = nil,
        httpapis: String? = nil
    ) -> UserConfig {
        UserConfig(
            appsubs: appsubs ?? self.appsubs,
            favapps: favapps ?? self.favapps,
            bgimgs: bgimgs ?? self.bgimgs,
            bgimg: bgimg ?? self.bgimg,
            name: name ?? self.name,
            icon: icon ?? self.icon,
            viewkeys: viewkeys ?? self.viewkeys,
            gist_cache_key: gist_cache_key ?? self.gist_cache_key,
            theme: theme ?? self.theme,
            isTransparentIcons: isTransparentIcons ?? self.isTransparentIcons,
            isWallpaperMode: isWallpaperMode ?? self.isWallpaperMode,
            isMute: isMute ?? self.isMute,
            isMuteQueryAlert: isMuteQueryAlert ?? self.isMuteQueryAlert,
            isHideHelp: isHideHelp ?? self.isHideHelp,
            isHideBoxIcon: isHideBoxIcon ?? self.isHideBoxIcon,
            isHideMyTitle: isHideMyTitle ?? self.isHideMyTitle,
            isHideCoding: isHideCoding ?? self.isHideCoding,
            isHideRefresh: isHideRefresh ?? self.isHideRefresh,
            isDebugWeb: isDebugWeb ?? self.isDebugWeb,
            lang: lang ?? self.lang,
            httpapi: httpapi ?? self.httpapi,
            httpapis: httpapis ?? self.httpapis
        )
    }

    /// `pathSuffix` 为 `usercfgs.` 之后的片段，如 `isMute`
    func updating(pathSuffix: String, value: Any) -> UserConfig? {
        switch pathSuffix {
        case "isMute":
            guard let v = value as? Bool else { return nil }
            return with(isMute: v)
        case "isMuteQueryAlert":
            guard let v = value as? Bool else { return nil }
            return with(isMuteQueryAlert: v)
        case "httpapi":
            guard let v = value as? String else { return nil }
            return with(httpapi: v)
        case "favapps":
            guard let v = value as? [String] else { return nil }
            return with(favapps: v)
        case "appsubs":
            guard let v = value as? [AppSub] else { return nil }
            return with(appsubs: v)
        case "name":
            guard let v = value as? String else { return nil }
            return with(name: v)
        case "icon":
            guard let v = value as? String else { return nil }
            return with(icon: v)
        case "viewkeys":
            guard let v = value as? [String] else { return nil }
            return with(viewkeys: v)
        case "gist_cache_key":
            guard let v = value as? [String] else { return nil }
            return with(gist_cache_key: v)
        default:
            return nil
        }
    }
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

struct Session: Codable, Identifiable {
    let id: String
    var name: String
    let enable: Bool
    let appId: String
    let appName: String
    let createTime: String
    var datas: [SessionData]
}

struct GlobalBackup: Codable, Identifiable {
    let id: String
    var name: String
    let createTime: String?
    let tags: [String]?
    var bak: AnyCodable?
}

struct DataQueryResp: Codable {
    let val: AnyCodable?
}

struct BoxDataResp: Codable {
    let appSubCaches: [String: AppSubCache]
    let datas: [String: AnyCodable?]
    var sessions: [Session]
    let usercfgs: UserConfig?
    let sysapps: [AppModel]
    let globalbaks: [GlobalBackup]?
    let curSessions: [String: String]?
    let syscfgs: SysCfgs?
    
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
    
    var bgImgUrl: String? {
        guard let bgimg = usercfgs?.bgimg, !bgimg.isEmpty else { return nil }
        return bgimg
    }
    
    func loadAppDataInfo(for app: AppModel) -> AppDataInfo {
        var appDatas: [SessionData] = []
        if let keys = app.keys {
            for key in keys {
                let val = datas[key] ?? nil
                appDatas.append(SessionData(key: key, val: val))
            }
        }
        let appSessions = sessions.filter { $0.appId == app.id }
        var curSession: Session? = nil
        if let curSessionId = curSessions?[app.id] {
            curSession = sessions.first { $0.id == curSessionId }
        }
        return AppDataInfo(datas: appDatas, sessions: appSessions, curSession: curSession)
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

    func replacingUsercfgs(_ usercfgs: UserConfig?) -> BoxDataResp {
        BoxDataResp(
            appSubCaches: appSubCaches,
            datas: datas,
            sessions: sessions,
            usercfgs: usercfgs,
            sysapps: sysapps,
            globalbaks: globalbaks,
            curSessions: curSessions,
            syscfgs: syscfgs
        )
    }
}


struct AppDataInfo {
    var datas: [SessionData]
    var sessions: [Session]
    var curSession: Session?
}

struct ScriptResp: Codable {
    var exception: String?
    var output: String?
}

struct VersionNote: Codable {
    let name: String
    let descs: [String]
}

struct VersionInfo: Codable, Identifiable {
    let version: String
    let notes: [VersionNote]
    var id: String { version }
}

struct VersionsResp: Codable {
    let releases: [VersionInfo]?
}

// Add syscfgs to BoxDataResp
struct SysEnv: Codable, Identifiable {
    let id: String
    let icons: [String]?
}

struct SysCfgs: Codable {
    let version: String?
    let env: String?
    let envs: [SysEnv]?
    let versionType: String?
}
