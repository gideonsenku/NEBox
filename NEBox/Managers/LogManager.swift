//
//  LogManager.swift
//  NEBox
//
//  Created by Senku on 2026.
//

import Foundation
import os.log
import UIKit

// MARK: - Log Level

enum LogLevel: String, CaseIterable, Comparable {
    case debug   = "DEBUG"
    case info    = "INFO"
    case warning = "WARN"
    case error   = "ERROR"

    var osLogType: OSLogType {
        switch self {
        case .debug:   return .debug
        case .info:    return .info
        case .warning: return .default
        case .error:   return .error
        }
    }

    private var sortOrder: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Log Category

enum LogCategory: String {
    case network   = "Network"
    case viewModel = "ViewModel"
    case ui        = "UI"
    case app       = "App"
}

// MARK: - LogManager

final class LogManager: @unchecked Sendable {
    static let shared = LogManager()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.nebox.logmanager", qos: .utility)
    private let maxFileSize: UInt64 = 2 * 1024 * 1024 // 2 MB
    private let fileHandle: LockedFileHandle

    private let osLoggers: [LogCategory: Logger] = {
        var map = [LogCategory: Logger]()
        for cat in [LogCategory.network, .viewModel, .ui, .app] {
            map[cat] = Logger(subsystem: "NEBox", category: cat.rawValue)
        }
        return map
    }()

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let logDir = caches.appendingPathComponent("NEBox/logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        self.fileURL = logDir.appendingPathComponent("nebox.log")

        // Create file if needed
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        self.fileHandle = LockedFileHandle(url: fileURL)

        // Startup banner
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let device = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let banner = "NEBox v\(appVersion)(\(build)) | \(device) | iOS \(systemVersion)"
        log(.info, category: .app, "──── App Launched ────")
        log(.info, category: .app, banner)
    }

    // MARK: - Public API

    func log(_ level: LogLevel, category: LogCategory, _ message: String,
             file: String = #fileID, function: String = #function, line: Int = #line) {
        let timestamp = Self.timestampFormatter.string(from: Date())
        let entry = "[\(timestamp)] [\(level.rawValue)] [\(category.rawValue)] \(message)\n"

        // os.log
        let logger = osLoggers[category] ?? Logger(subsystem: "NEBox", category: category.rawValue)
        logger.log(level: level.osLogType, "\(message, privacy: .public)")

        // File write
        queue.async { [weak self] in
            self?.appendToFile(entry)
        }
    }

    /// URL of the log file, for sharing
    var logFileURL: URL { fileURL }

    /// Read the entire log file content
    func readLogs() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }

    /// Export the full log file as Data, for sharing or upload.
    func exportLogData() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// Clear all logs
    func clearLogs() {
        queue.async { [weak self] in
            guard let self else { return }
            self.fileHandle.truncate()
        }
    }

    // MARK: - File I/O

    private func appendToFile(_ entry: String) {
        fileHandle.append(entry)
        rotateIfNeeded()
    }

    private func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? UInt64,
              size > maxFileSize else { return }

        // Keep the last half of the file
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let half = data.count / 2
        // Find the first newline after the midpoint to avoid cutting a line
        var cutIndex = half
        while cutIndex < data.count {
            if data[cutIndex] == UInt8(ascii: "\n") {
                cutIndex += 1
                break
            }
            cutIndex += 1
        }
        let trimmed = data.subdata(in: cutIndex..<data.count)
        fileHandle.overwrite(trimmed)
    }
}

// MARK: - Thread-safe file handle wrapper

private final class LockedFileHandle: @unchecked Sendable {
    private var handle: FileHandle?
    private let url: URL

    init(url: URL) {
        self.url = url
        self.handle = FileHandle(forWritingAtPath: url.path)
        self.handle?.seekToEndOfFile()
    }

    func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        handle?.seekToEndOfFile()
        handle?.write(data)
    }

    func truncate() {
        handle?.truncateFile(atOffset: 0)
        handle?.synchronizeFile()
    }

    func overwrite(_ data: Data) {
        handle?.truncateFile(atOffset: 0)
        handle?.seek(toFileOffset: 0)
        handle?.write(data)
        handle?.synchronizeFile()
    }
}

// MARK: - Convenience global function

func appLog(_ level: LogLevel, category: LogCategory, _ message: String,
            file: String = #fileID, function: String = #function, line: Int = #line) {
    LogManager.shared.log(level, category: category, message, file: file, function: function, line: line)
}
