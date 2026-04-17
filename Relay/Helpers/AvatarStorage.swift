//
//  AvatarStorage.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import Foundation

enum AvatarStorage {
    private static let fileName = "user_avatar.png"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func save(_ image: PlatformImage) -> Bool {
        guard let data = image.pngRepresentation() else { return false }
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            appLog(.error, category: .app, "Failed to save avatar: \(error)")
            return false
        }
    }

    static func load() -> PlatformImage? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return PlatformImage(contentsOfFile: fileURL.path)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    static var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
}
