//
//  MacIconAppearance.swift
//  RelayMac
//

import SwiftUI

enum MacIconAppearance: String, CaseIterable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"

    static let userDefaultsKey = "iconAppearance"

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    func isDark(systemIsDark: Bool) -> Bool {
        switch self {
        case .auto: return systemIsDark
        case .light: return false
        case .dark: return true
        }
    }
}
