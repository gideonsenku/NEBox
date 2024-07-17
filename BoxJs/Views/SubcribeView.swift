//
//  SubcribeView.swift
//  BoxJs
//
//  Created by Senku on 7/4/24.
//

import SwiftUI

struct SubcribeView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/).likeButtonStyle()
    }
}

struct LikeBtnModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

extension Text {
    func likeButtonStyle() -> some View {
        modifier(LikeBtnModifier())
    }
}

#Preview {
    SubcribeView()
}
