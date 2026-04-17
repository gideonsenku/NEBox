//
//  Utils.swift
//  BoxJs
//
//  Created by Senku on 8/13/24.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
func openInSafari(for urlString: String?) {
    guard let urlString = urlString, let url = URL(string: urlString) else {
        appLog(.warning, category: .app, "Invalid URL: \(urlString ?? "nil")")
        return
    }
    PlatformBridge.open(url)
}

func copyToClipboard(text: String) {
    PlatformBridge.copyToPasteboard(text)
}

#if os(iOS)
func showTextFieldAlert(title: String?, message: String?, placeholder: String?, confirmButtonTitle: String, cancelButtonTitle: String, onConfirm: @escaping (String) -> Void) {
    // 获取当前的 UIViewController
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
        return
    }

    // 创建 UIAlertController
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    // 添加文本输入框
    alertController.addTextField { textField in
        textField.placeholder = placeholder
    }

    // 添加 "取消" 按钮
    let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    // 添加 "确定" 按钮
    let confirmAction = UIAlertAction(title: confirmButtonTitle, style: .default) { _ in
        if let textField = alertController.textFields?.first {
            onConfirm(textField.text ?? "")
        }
    }
    alertController.addAction(confirmAction)

    // 显示 UIAlertController
    rootViewController.present(alertController, animated: true, completion: nil)
}
#endif
