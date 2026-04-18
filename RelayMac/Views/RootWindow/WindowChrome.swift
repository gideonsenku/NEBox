//
//  WindowChrome.swift
//  RelayMac
//

import SwiftUI

struct WindowChromeAction: Identifiable {
    enum Kind {
        case button(action: () -> Void)
        case menu(items: [WindowChromeMenuItem])
    }

    let id = UUID()
    let title: String
    let systemImage: String
    var isPrimary: Bool = false
    var isDisabled: Bool = false
    var kind: Kind
}

struct WindowChromeMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String?
    var role: ButtonRole? = nil
    var isDisabled: Bool = false
    let action: () -> Void
}

@MainActor
final class WindowChromeModel: ObservableObject {
    @Published var actions: [WindowChromeAction] = []

    func setActions(_ actions: [WindowChromeAction]) {
        self.actions = actions
    }

    func clear() {
        actions = []
    }
}
