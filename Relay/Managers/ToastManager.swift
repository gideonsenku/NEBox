//
//  ToastManager.swift
//  NEBox
//
//  Created by Senku on 8/14/24.
//

import Foundation
import SwiftUI

@MainActor
class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message: String = ""
    @Published var loadingMessage: String?

    func showToast(message: String, duration: TimeInterval = 2.0) {
        self.message = message
        withAnimation {
            self.isShowing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.isShowing = false
            }
        }
    }

    func showLoading(message: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.loadingMessage = message
        }
    }

    func hideLoading() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.loadingMessage = nil
        }
    }
}
