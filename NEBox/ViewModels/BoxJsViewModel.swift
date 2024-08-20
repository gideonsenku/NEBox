//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI

class BoxJsViewModel: ObservableObject {
    @Published var favApps: [AppModel]
    @Published var boxData: BoxDataResp {
        didSet {
            favApps = boxData.favApps
        }
    }
    private let iconThemeIdx = 0

    init(boxData: BoxDataResp = BoxDataResp(
        appSubCaches: [:],
//        datas: [:],
        usercfgs: UserConfig(appsubs: [], favapps: [], bgimgs: "", bgimg: ""),
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
                }
            } catch {
                print("Error fetching data: \(error)")
            }

        }
    }
    
    func reloadAppSub(url: String) async {
        do {
            let boxdata = try await ApiRequest.reloadAppSub(url: url)
            DispatchQueue.main.async {
                self.boxData = boxdata
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    func deleteAppSub(url: String) async {
        do {
            let boxdata = try await ApiRequest.deleteAppSub(url: url)
            DispatchQueue.main.async {
                self.boxData = boxdata
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }

}
