//
//  EnvScriptLoader.swift
//  NEBox
//

import Foundation

/// Loads chavyleung's Env.js for `runTxtScript` so editor scripts can use `Env` / `$`.
enum EnvScriptLoader {
    /// [Env.min.js](https://raw.githubusercontent.com/chavyleung/scripts/refs/heads/master/Env.min.js)
    static let envMinURL = URL(string: "https://raw.githubusercontent.com/chavyleung/scripts/refs/heads/master/Env.min.js")!

    private static let cacheDirectoryName = "EnvScriptLoader"
    private static let cacheFileName = "Env.min.js"

    /// ~1 day; refresh from network after this.
    private static let cacheTTL: TimeInterval = 24 * 60 * 60

    private static var memoryCache: String?
    private static let lock = NSLock()

    private static var cacheFileURL: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches
            .appendingPathComponent(cacheDirectoryName, isDirectory: true)
            .appendingPathComponent(cacheFileName, isDirectory: false)
    }

    /// Loads Env.min.js: memory → valid disk cache → network; on failure uses stale disk if present.
    static func loadEnvMinScript() async throws -> String {
        lock.lock()
        if let cached = memoryCache {
            lock.unlock()
            return cached
        }
        lock.unlock()

        if let text = loadFromDisk(validWithinTTL: true) {
            lock.lock()
            memoryCache = text
            lock.unlock()
            return text
        }

        do {
            let text = try await fetchFromNetwork()
            try saveToDisk(text)
            lock.lock()
            memoryCache = text
            lock.unlock()
            return text
        } catch {
            if let stale = loadFromDisk(validWithinTTL: false) {
                lock.lock()
                memoryCache = stale
                lock.unlock()
                return stale
            }
            throw error
        }
    }

    private static func loadFromDisk(validWithinTTL: Bool) -> String? {
        let path = cacheFileURL.path
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date
        else { return nil }

        if validWithinTTL, Date().timeIntervalSince(modDate) >= cacheTTL {
            return nil
        }

        guard let data = try? Data(contentsOf: cacheFileURL),
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty
        else { return nil }

        return text
    }

    private static func fetchFromNetwork() async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: envMinURL)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            throw URLError(.cannotDecodeContentData)
        }
        return text
    }

    private static func saveToDisk(_ text: String) throws {
        let dir = cacheFileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: cacheFileURL, options: .atomic)
    }
}
