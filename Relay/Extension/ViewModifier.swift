//
//  ViewModifier.swift
//  BoxJs
//
//  Created by Senku on 7/19/24.
//

import Foundation
import SwiftUI
import UIKit

struct BackgroundImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Image("1")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}


extension View {
    func backgroundImage() -> some View {
        self.modifier(BackgroundImageModifier())
    }
}


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgba: UInt64 = 0
        scanner.scanHexInt64(&rgba)

        let length = hex.replacingOccurrences(of: "#", with: "").count
        let r, g, b, a: Double
        if length >= 8 {
            r = Double((rgba & 0xFF000000) >> 24) / 255.0
            g = Double((rgba & 0x00FF0000) >> 16) / 255.0
            b = Double((rgba & 0x0000FF00) >> 8) / 255.0
            a = Double(rgba & 0x000000FF) / 255.0
        } else {
            r = Double((rgba & 0xFF0000) >> 16) / 255.0
            g = Double((rgba & 0x00FF00) >> 8) / 255.0
            b = Double(rgba & 0x0000FF) / 255.0
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int((components[safe: 0] ?? 0) * 255)
        let g = Int((components[safe: 1] ?? 0) * 255)
        let b = Int((components[safe: 2] ?? 0) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    // MARK: - Design Tokens

    // Accent
    static let accent = Color(hex: "#002FA7")
    static let accentDark = Color(hex: "#001F73")
    static let accentLight = Color(hex: "#E0E8F7")
    static let accentCoral = Color(hex: "#F5A623")
    static let accentRed = Color(hex: "#D0534F")
    static let accentWarning = Color(hex: "#D4A64A")

    // Text
    static let textPrimary = Color(hex: "#0F1729")
    static let textSecondary = Color(hex: "#5A6177")
    static let textTertiary = Color(hex: "#9098AD")
    static let textInactive = Color(hex: "#A0A8BD")

    // Background
    static let bgPage = Color(hex: "#F5F6FA")
    static let bgCard = Color(hex: "#FFFFFF")
    static let bgElevated = Color(hex: "#FAFAF8")
    static let bgMuted = Color(hex: "#ECEEF4")

    // Border
    static let borderSubtle = Color(hex: "#E2E5EE")
    static let borderStrong = Color(hex: "#C8CDD9")
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Enable swipe back gesture when navigation bar is hidden

private struct SwipeBackEnabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = SwipeBackView()
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

private class SwipeBackView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        enableSwipeBack()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        enableSwipeBack()
    }

    private func enableSwipeBack() {
        guard let nav = findNavigationController() else { return }
        nav.interactivePopGestureRecognizer?.isEnabled = true
        nav.interactivePopGestureRecognizer?.delegate = nil
    }

    private func findNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let nav = next as? UINavigationController {
                return nav
            }
            responder = next
        }
        return nil
    }
}

extension View {
    func enableSwipeBack() -> some View {
        background(SwipeBackEnabler())
    }
}

// MARK: - iOS 15 Navigation Compatibility

@ViewBuilder
func neboxNavigationContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    if #available(iOS 16.0, *) {
        NavigationStack {
            content()
        }
    } else {
        NavigationView {
            content()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

extension View {
    @ViewBuilder
    func neboxHiddenNavigationBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            self
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    func neboxNavigationDestination<Destination: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        if #available(iOS 16.0, *) {
            self.navigationDestination(isPresented: isPresented, destination: destination)
        } else {
            self.background(
                NavigationLink(destination: destination(), isActive: isPresented) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }

    @ViewBuilder
    func neboxMediumSheet() -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }

    @ViewBuilder
    func neboxSheetPresentation() -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }

    @ViewBuilder
    func neboxHideTabBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbar(.hidden, for: .tabBar)
                .preference(key: NEBoxHideTabBarPreferenceKey.self, value: true)
        } else {
            self
                .preference(key: NEBoxHideTabBarPreferenceKey.self, value: true)
        }
    }
}

struct NEBoxHideTabBarPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - iOS 26 Liquid Glass Modifiers

/// Glass effect for floating tab bars and pill-shaped containers
struct GlassTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
        }
    }
}

/// Glass effect for card containers
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }
}

/// Glass effect for prominent buttons
struct GlassButtonModifier: ViewModifier {
    let isDisabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .opacity(isDisabled ? 0.5 : 1.0)
        } else {
            content
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isDisabled ? Color.gray.opacity(0.4) : Color.accentColor)
                )
        }
    }
}

extension View {
    func glassTabBar() -> some View {
        modifier(GlassTabBarModifier())
    }

    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassButton(isDisabled: Bool = false) -> some View {
        modifier(GlassButtonModifier(isDisabled: isDisabled))
    }
}

// MARK: - Tab bar colors

/// Single place to tweak **native `TabView`** (`.tint` + `UITabBar` tints) and the **custom floating bar** on older iOS.
enum NEBoxTabBarPalette {
    static let selected = Color(hex: "#002FA7")
    static let unselected = Color(hex: "#A0A8BD")

    /// Keep RGB in sync with the hex above — `UITabBar` uses UIKit colors.
    static let selectedUIKit = UIColor(red: 0, green: 47 / 255, blue: 167 / 255, alpha: 1)
    static let unselectedUIKit = UIColor(red: 160 / 255, green: 168 / 255, blue: 189 / 255, alpha: 1)
}

// MARK: - iOS Version Adaptive Utilities

/// Returns the appropriate bottom inset for content views
/// - iOS 26+: Native TabView with Liquid Glass tab bar (~90pt)
/// - iOS < 26: Account for custom floating tab bar (110pt)
func adaptiveBottomInset() -> CGFloat {
    if #available(iOS 26.0, *) {
        return 90
    } else {
        return 110
    }
}

// MARK: - iOS 26 Tab bar (Liquid Glass)

extension View {
    /// Per-tab toolbar chrome for native `TabView` on iOS 26+ (attach to each tab’s root, not `TabView`).
    @ViewBuilder
    func neboxLiquidGlassTabBarChrome() -> some View {
        if #available(iOS 26.0, *) {
            self
                .toolbarBackground(
                    LinearGradient(
                        colors: [Color(hex: "#EEF0FA"), Color(hex: "#F0EDF8"), Color(hex: "#F5F0F8")],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    for: .tabBar
                )
                .toolbarBackgroundVisibility(.visible, for: .tabBar)
        } else {
            self
        }
    }
}
