//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI

class BoxJsViewModel: ObservableObject {
    @Published var boxData: BoxDataModel
    @Published var appSubCaches: [String: AppSubCache]
    @Published var appSubs: [AppSub]
    @Published var apps: [AppModel]
    @Published var subApps: [SysApp]
    private let iconThemeIdx = 0
    
    init(boxData: BoxDataModel = BoxDataModel(
        appSubCaches: [:],
        datas: [:],
        usercfgs: UserConfig(favapps: [], appsubs: []),
        sysapps: []
    )) {
        self.boxData = boxData
        self.appSubCaches = [:]
        self.appSubs = []
        self.apps = []
        self.subApps = []
    }
    
    func fetchData() {
        Task {
            do {
                let fetchedData = try await NetworkService.shared.getBoxData()
                DispatchQueue.main.async {
                    self.boxData = fetchedData
                    self.appSubCaches = self.getAppSubCaches()
                    self.appSubs = self.getAppSubs()
                    self.subApps = self.getSubApps()
                    
                    print(self.subApps[0])
                }
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
    
    func getAppSubCaches() -> [String: AppSubCache] {
        var ids = [String]()
        let appSubs = self.boxData.usercfgs.appsubs
        appSubs.forEach { appSub in
            // 查找 appSubCaches 中对应的缓存
            if let sub = self.boxData.appSubCaches[appSub.url], !(appSub.isErr ?? false) {
                // 判断 sub 是否存在，sub.apps 是否是数组，!appsub.isErr
                if !sub.apps.isEmpty {
                    ids.append(contentsOf: sub.apps.map { $0.id })
                }
            }
        }
        
        let replyIds = ids.enumerated().compactMap { (index, value) in
            return ids[(index + 1)...].contains(value) ? value : nil
        }
        
        var updatedAppSubCaches = self.boxData.appSubCaches
        
        self.boxData.usercfgs.appsubs.forEach { appSub in
            if let sub = updatedAppSubCaches[appSub.url], !(appSub.isErr ?? false) {
                if !sub.apps.isEmpty {
                    // 创建新的 apps 数组
                    let updatedApps = sub.apps.map { app in
                        if replyIds.contains(app.id) {
                            return app.withId("\(app.author)_\(app.id)")
                        } else {
                            return app
                        }
                    }
                    // 创建新的 AppSubCache 实例
                    let updatedSub = sub.withApps(updatedApps)
                    updatedAppSubCaches[appSub.url] = updatedSub
                }
            }
        }
        return updatedAppSubCaches
    }
    
    func getAppSubs() -> [AppSub] {
        var subs = self.boxData.usercfgs.appsubs
        subs = subs.map { sub in
            var newSub = sub
            if let cacheSub = self.appSubCaches[sub.url], cacheSub.isValid {
                newSub = sub.merged(with: cacheSub)
            } else {
                newSub.isErr = true
                newSub.apps = []
            }
            newSub.name = newSub.name ?? "匿名订阅"
            newSub.author = newSub.author ?? "@anonymous"
            newSub.repo = newSub.repo ?? sub.url
            return newSub
        }
        return subs
    }
    
    func getSubApps() -> [SysApp] {
        var apps: [SysApp] = []
        
        self.appSubs.forEach { appSub in
            if let sub = self.appSubCaches[appSub.url], !(appSub.isErr ?? false) {
                sub.apps.forEach { app in
                    apps.append(self.loadAppBaseInfo(app))
                }
            }
        }
        return apps
    }
    
    func loadAppBaseInfo(_ app: SysApp) -> SysApp {
        var icons = app.icons.isEmpty ? ["https://raw.githubusercontent.com/Orz-3/mini/master/Alpha/appstore.png", "https://raw.githubusercontent.com/Orz-3/mini/master/Color/appstore.png"] : app.icons
        
        if app.icons.first(where: { $0.contains("/Orz-3/task/master/") }) != nil {
            icons[0] = app.icons[0].replacingOccurrences(of: "/Orz-3/mini/master/", with: "/Orz-3/mini/master/Alpha/")
            icons[1] = app.icons[1].replacingOccurrences(of: "/Orz-3/task/master/", with: "/Orz-3/mini/master/Color/")
        }
        let isFav = self.boxData.usercfgs.favapps.contains(app.id)
        let newApp = app.withIcon(icons, icons[self.iconThemeIdx], isFav ? "mdi-star" : "mdi-star-outline", isFav ? "primary" : "grey")

        return newApp
    }
}
