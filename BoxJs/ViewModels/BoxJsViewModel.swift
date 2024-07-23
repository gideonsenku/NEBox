//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI

class BoxJsViewModel: ObservableObject {
    @Published var boxData: BoxDataResp
    @Published var favApps: [AppModel]
    private let iconThemeIdx = 0

    init(boxData: BoxDataResp = BoxDataResp(
        appSubCaches: [:],
//        datas: [:],
        usercfgs: UserConfig(appsubs: [], favapps: []),
        sysapps: []
    )) {
        self.boxData = boxData
        favApps = []
    }

    func fetchData() {
        Task {
            do {
                let boxdata = try await ApiRequest.getBoxData()
                DispatchQueue.main.async {
                    self.boxData = boxdata
                    self.favApps = boxdata.favApps
                }
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
    
    func updateData(path: String, data: Any) {
        Task {
            do {
                let boxdata = try await ApiRequest.updateData(path: path, data: data)
                DispatchQueue.main.async {
                    self.boxData = boxdata
                    self.favApps = boxdata.favApps
                    print(self.favApps.map { $0.id })
                }
            } catch {
                print("Error fetching data: \(error)")
            }

        }
    }
}
