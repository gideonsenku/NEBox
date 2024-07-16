//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI

class BoxJsViewModel: ObservableObject {
    @Published var boxData: BoxDataModel?
    
    func fetchData() {
        Task {
            do {
                let fetchedData = try await NetworkService.shared.getBoxData()
                DispatchQueue.main.async {
                    self.boxData = fetchedData
                }
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
}
