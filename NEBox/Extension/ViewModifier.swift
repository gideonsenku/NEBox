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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
