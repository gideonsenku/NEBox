//
//  ApiManager.swift
//  NEBox
//
//  Created by Senku on 10/16/24.
//
import SwiftUI

class ApiManager: ObservableObject {
    @Published var apiUrl: String? {
        didSet {
            if let url = apiUrl {
                UserDefaults.standard.set(url, forKey: "apiUrl")
            } else {
                UserDefaults.standard.removeObject(forKey: "apiUrl")
            }
        }
    }

    init() {
        self.apiUrl = UserDefaults.standard.string(forKey: "apiUrl")
    }

    func isApiUrlSet() -> Bool {
        return apiUrl != nil && !apiUrl!.isEmpty
    }
}
