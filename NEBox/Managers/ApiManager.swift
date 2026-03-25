//
//  ApiManager.swift
//  NEBox
//
//  Created by Senku on 10/16/24.
//
import SwiftUI
import os.log

private let apiLog = Logger(subsystem: "NEBox", category: "ToolSwitch")

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

    /// Per-tool URL map, e.g. ["loon": "http://…", "surge": "http://…"]
    @Published var toolUrls: [String: String] {
        didSet { UserDefaults.standard.set(toolUrls, forKey: "toolUrls") }
    }

    /// Explicitly-selected tool ID — source of truth for "which tool is active"
    @Published var selectedToolId: String? {
        didSet { UserDefaults.standard.set(selectedToolId, forKey: "selectedToolId") }
    }


    init() {
        self.apiUrl = UserDefaults.standard.string(forKey: "apiUrl")
        self.toolUrls = UserDefaults.standard.dictionary(forKey: "toolUrls") as? [String: String] ?? [:]
        self.selectedToolId = UserDefaults.standard.string(forKey: "selectedToolId")
    }

    func isApiUrlSet() -> Bool {
        return apiUrl != nil && !apiUrl!.isEmpty
    }

    /// Returns the base URL with no trailing slash, e.g. "http://boxjs.com"
    var baseURL: String {
        guard let url = apiUrl, !url.isEmpty else { return "http://boxjs.com" }
        return url.hasSuffix("/") ? String(url.dropLast()) : url
    }

    func registerTool(_ toolId: String, url: String) {
        var trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") { trimmed = String(trimmed.dropLast()) }
        toolUrls[toolId] = trimmed
        apiLog.info("📝 registerTool: \(toolId) → \(trimmed)")
    }

    /// Returns true if the switch happened (URL was known)
    @discardableResult
    func switchToTool(_ toolId: String) -> Bool {
        apiLog.info("🔀 switchToTool: \(toolId)")
        guard let url = toolUrls[toolId] else {
            apiLog.warning("⚠️ no URL for \(toolId)")
            return false
        }
        apiLog.info("✅ selectedToolId=\(toolId) apiUrl → \(url)")
        selectedToolId = toolId
        apiUrl = url
        return true
    }
}
