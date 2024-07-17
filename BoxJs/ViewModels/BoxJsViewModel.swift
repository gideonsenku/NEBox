//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI

class BoxJsViewModel: ObservableObject {
    @Published var boxData: BodxDataResp
    private let iconThemeIdx = 0

    init(boxData: BodxDataResp = BodxDataResp(
        appSubCaches: [:],
//        datas: [:],
        usercfgs: UserConfig(appsubs: [], favapps: []),
        sysapps: []
    )) {
        self.boxData = boxData
    }

    func fetchData() {
        Task {
            do {
                let boxdata = try await ApiRequest.getBoxData()
                DispatchQueue.main.async {
                    self.boxData = boxdata
                    print(boxdata.displaySubApps)
                }
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
}
