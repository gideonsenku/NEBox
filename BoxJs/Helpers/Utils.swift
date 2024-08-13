//
//  Utils.swift
//  BoxJs
//
//  Created by Senku on 8/13/24.
//

import Foundation
import UIKit

func openInSafari(for urlString: String?) {
    guard let urlString = urlString, let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }
    
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}


func copyToClipboard(text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
    print("Text copied to clipboard: \(text)")
}
