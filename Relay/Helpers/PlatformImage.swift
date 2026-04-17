//
//  PlatformImage.swift
//  Relay (shared)
//
//  Cross-platform `PlatformImage` typealias + SwiftUI `Image` convenience
//  initializer so shared code (AvatarStorage, etc.) can work with a single
//  image type that maps to UIImage on iOS and NSImage on macOS.
//

import SwiftUI

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

extension Image {
    init(platformImage image: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: image)
        #elseif os(macOS)
        self.init(nsImage: image)
        #endif
    }
}

extension PlatformImage {
    /// JPEG data at the given compression quality (0.0–1.0).
    func jpegRepresentation(compressionQuality: CGFloat) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
        #endif
    }

    /// PNG data.
    func pngRepresentation() -> Data? {
        #if os(iOS)
        return self.pngData()
        #elseif os(macOS)
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #endif
    }
}
