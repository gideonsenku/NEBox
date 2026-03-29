//
//  ApiManager.swift
//  NEBox
//
//  Created by Senku on 10/16/24.
//
import SwiftUI

class ApiManager: ObservableObject {
    static let shared = ApiManager()
    static let defaultAPIURL = "https://boxjs.com"

    @Published var apiUrl: String? {
        didSet {
            if let url = apiUrl {
                UserDefaults.standard.set(url, forKey: "apiUrl")
                appLog(.info, category: .app, "[ApiManager] apiUrl updated: \(url)")
            } else {
                UserDefaults.standard.removeObject(forKey: "apiUrl")
                appLog(.warning, category: .app, "[ApiManager] apiUrl cleared")
            }
        }
    }

    init() {
        self.apiUrl = UserDefaults.standard.string(forKey: "apiUrl")
        appLog(.info, category: .app, "[ApiManager] restored apiUrl: \(self.apiUrl ?? "nil")")
    }

    func isApiUrlSet() -> Bool {
        return apiUrl != nil && !apiUrl!.isEmpty
    }

    /// Returns the base URL with no trailing slash, e.g. `ApiManager.defaultAPIURL`
    var baseURL: String {
        guard let url = apiUrl, !url.isEmpty else { return Self.defaultAPIURL }
        return url.hasSuffix("/") ? String(url.dropLast()) : url
    }
}
