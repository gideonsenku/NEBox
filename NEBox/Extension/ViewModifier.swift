//
//  ViewModifier.swift
//  BoxJs
//
//  Created by Senku on 7/19/24.
//

import Foundation
import SwiftUI

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
        
        let r = Double((rgba & 0xFF000000) >> 24) / 255.0
        let g = Double((rgba & 0x00FF0000) >> 16) / 255.0
        let b = Double((rgba & 0x0000FF00) >> 8) / 255.0
        let a = Double(rgba & 0x000000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
