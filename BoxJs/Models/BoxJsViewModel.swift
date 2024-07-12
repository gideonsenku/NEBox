//
//  BoxJsViewModel.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import SwiftUI

class BoxJsViewModel: ObservableObject {
    @Published var boxResponse: BoxResponse?
    
    func fetchData() {
        Task {
            do {
                let fetchedData = try await NetworkService.shared.getBoxData()
                DispatchQueue.main.async {
                    self.boxResponse = fetchedData
                    print(self.boxResponse?.sysapps)
                }
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
}
