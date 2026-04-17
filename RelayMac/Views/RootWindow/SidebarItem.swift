//
//  SidebarItem.swift
//  RelayMac
//

import SwiftUI

enum SidebarItem: String, Hashable, CaseIterable, Identifiable {
    case home
    case search
    case subscriptions
    case scripts
    case logs
    case backup
    case profile
    case preferences
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:          return "收藏应用"
        case .search:        return "搜索"
        case .subscriptions: return "订阅源"
        case .scripts:       return "脚本编辑器"
        case .logs:          return "日志"
        case .backup:        return "备份"
        case .profile:       return "个人资料"
        case .preferences:   return "偏好设置"
        case .about:         return "关于"
        }
    }

    var systemImage: String {
        switch self {
        case .home:          return "star.fill"
        case .search:        return "magnifyingglass"
        case .subscriptions: return "rectangle.stack"
        case .scripts:       return "curlybraces"
        case .logs:          return "doc.text.magnifyingglass"
        case .backup:        return "externaldrive"
        case .profile:       return "person.crop.circle"
        case .preferences:   return "gearshape"
        case .about:         return "info.circle"
        }
    }

    enum Group: String, CaseIterable {
        case apps      = "应用"
        case tools     = "工具"
        case system    = "系统"
    }

    var group: Group {
        switch self {
        case .home, .search, .subscriptions:        return .apps
        case .scripts, .logs, .backup:              return .tools
        case .profile, .preferences, .about:        return .system
        }
    }
}
