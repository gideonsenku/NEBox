//
//  PlatformColors.swift
//  Relay (shared)
//
//  Cross-platform Color aliases so shared code can reference semantic colors
//  without importing UIKit or using `#if os` at every call site.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension Color {

    static var relaySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var relaySecondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color(nsColor: .underPageBackgroundColor)
        #endif
    }

    static var relayTertiarySystemFill: Color {
        #if os(iOS)
        return Color(.tertiarySystemFill)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }

    static var relayTertiaryLabel: Color {
        #if os(iOS)
        return Color(.tertiaryLabel)
        #else
        return Color.secondary.opacity(0.6)
        #endif
    }

    static var relaySystemGray6: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.secondary.opacity(0.08)
        #endif
    }

    static var relayPlaceholderText: Color {
        #if os(iOS)
        return Color(.placeholderText)
        #else
        return Color.secondary
        #endif
    }
}
