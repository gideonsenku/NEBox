//
//  MacRoute.swift
//  RelayMac
//

import Foundation

/// Navigation values pushed onto the detail column's `NavigationStack`.
enum MacRoute: Hashable {
    case app(id: String)
    case subscription(url: String)
    case backup(id: String)
}
