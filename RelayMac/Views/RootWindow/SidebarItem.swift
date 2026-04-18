//
//  SidebarItem.swift
//  RelayMac
//

import SwiftUI

enum SidebarItem: String, Hashable, CaseIterable, Identifiable {
    case home
    case subscriptions
    case scripts
    case dataViewer
    case backup
    case logs
    case preferences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:          return "收藏应用"
        case .subscriptions: return "订阅源"
        case .scripts:       return "脚本工坊"
        case .dataViewer:    return "数据查看器"
        case .backup:        return "备份"
        case .logs:          return "日志"
        case .preferences:   return "偏好设置"
        }
    }

    var systemImage: String {
        switch self {
        case .home:          return "star.fill"
        case .subscriptions: return "rectangle.stack"
        case .scripts:       return "curlybraces"
        case .dataViewer:    return "text.magnifyingglass"
        case .backup:        return "externaldrive"
        case .logs:          return "doc.text.magnifyingglass"
        case .preferences:   return "gearshape"
        }
    }

    enum Group: String, CaseIterable {
        case apps      = "应用"
        case tools     = "工具"
        case system    = "系统"
    }

    var group: Group {
        switch self {
        case .home, .subscriptions:         return .apps
        case .scripts, .dataViewer, .backup: return .tools
        case .logs, .preferences:           return .system
        }
    }

    /// Items that render directly onto the window background, without the default
    /// rounded detail card. Used for sections with their own card-like chrome
    /// (e.g. the Log Center, which has its own title bar + table card).
    var usesBareLayout: Bool {
        switch self {
        case .logs, .dataViewer, .scripts, .backup, .preferences: return true
        default:                                                  return false
        }
    }
}
