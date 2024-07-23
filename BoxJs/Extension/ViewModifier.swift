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
