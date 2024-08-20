//
//  GlobalToastView.swift
//  BoxJs
//
//  Created by Senku on 8/14/24.
//

import SwiftUI

struct GlobalToastView: View {
    @EnvironmentObject var toastManager: ToastManager

    var body: some View {
        if toastManager.isShowing {
            Text(toastManager.message)
                .font(.body)
                .padding()
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.top, 50)  // Adjust position as needed
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3))
                .zIndex(1)
        }
    }
}
