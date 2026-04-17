//
//  PlatformBridge.swift
//  Relay (shared)
//
//  Cross-platform facade for UIKit/AppKit APIs that are used from shared code.
//  View layers should call these helpers instead of importing UIKit/AppKit directly.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum PlatformBridge {

    // MARK: - Pasteboard

    static func copyToPasteboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    static func pasteboardString() -> String? {
        #if os(iOS)
        return UIPasteboard.general.string
        #elseif os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #endif
    }

    // MARK: - URL opening

    @MainActor
    static func open(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    // MARK: - Haptics

    enum HapticStyle { case light, medium, heavy }

    @MainActor
    static func impact(_ style: HapticStyle = .medium) {
        #if os(iOS)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch style {
            case .light:  return .light
            case .medium: return .medium
            case .heavy:  return .heavy
            }
        }()
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        #endif
    }

    @MainActor
    static func notify(success: Bool) {
        #if os(iOS)
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(success ? .success : .error)
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(
            success ? .generic : .alignment,
            performanceTime: .default
        )
        #endif
    }

    // MARK: - First responder / keyboard

    @MainActor
    static func resignFirstResponder() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
        // macOS: no-op. Click away handles focus release.
    }
}
