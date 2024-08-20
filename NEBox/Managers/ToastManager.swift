//
//  ToastManager.swift
//  NEBox
//
//  Created by Senku on 8/14/24.
//

import Foundation
import SwiftUI

class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message: String = ""

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
}
