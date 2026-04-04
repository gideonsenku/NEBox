//
//  AvatarStorage.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import UIKit

enum AvatarStorage {
    private static let fileName = "user_avatar.png"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func save(_ image: UIImage) -> Bool {
        guard let data = image.pngData() else { return false }
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            appLog(.error, category: .app, "Failed to save avatar: \(error)")
            return false
        }
    }

    static func load() -> UIImage? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    static var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
}
