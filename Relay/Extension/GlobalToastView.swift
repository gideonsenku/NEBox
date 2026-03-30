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

struct GlobalLoadingOverlay: View {
    @ObservedObject var toastManager: ToastManager

    var body: some View {
        if let message = toastManager.loadingMessage {
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(width: 120, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }
}
