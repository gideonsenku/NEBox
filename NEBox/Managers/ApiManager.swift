//
//  ApiManager.swift
//  NEBox
//
//  Created by Senku on 10/16/24.
//
import SwiftUI

class ApiManager: ObservableObject {
    static let shared = ApiManager()

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

    /// Returns the base URL with no trailing slash, e.g. "http://boxjs.com"
    var baseURL: String {
        guard let url = apiUrl, !url.isEmpty else { return "http://boxjs.com" }
        // Strip trailing slash
        return url.hasSuffix("/") ? String(url.dropLast()) : url
    }
}
