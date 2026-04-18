//
//  MacLogViewerView.swift
//  RelayMac
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacLogViewerView: View {
    @EnvironmentObject var chrome: WindowChromeModel
    @EnvironmentObject var toastManager: ToastManager

    @State private var logText: String = ""
    @State private var filter: String = ""
    @State private var selectedLevel: LogLevel?
    @State private var showClearConfirm: Bool = false

    private var filteredLines: [String] {
        let needle = filter.trimmingCharacters(in: .whitespaces)
        let lines = logText
            .components(separatedBy: "\n")
            .filter { line in
                guard !line.isEmpty else { return false }
                if let level = selectedLevel, !line.contains("[\(level.rawValue)]") {
                    return false
                }
                if !needle.isEmpty, !line.localizedCaseInsensitiveContains(needle) {
                    return false
                }
                return true
            }
        return lines.reversed()
    }

    private var filteredText: String {
        filteredLines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            filterBar
            tableCard
        }
        .onAppear {
            refresh()
            chrome.clear()
        }
        .confirmationDialog(
            "确认清空所有日志？",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("清空", role: .destructive) {
                LogManager.shared.clearLogs()
                logText = ""
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("日志")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)

            entryCountBadge

            Spacer(minLength: 16)

            searchField
                .frame(width: 220)

            refreshButton

            exportButton

            clearButton
        }
    }

    private var refreshButton: some View {
        Button(action: refresh) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("刷新")
    }

    private var entryCountBadge: some View {
        Text("\(filteredLines.count) 条")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            TextField("搜索日志…", text: $filter)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.94, green: 0.94, blue: 0.95).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        )
    }

    private var exportButton: some View {
        Menu {
            Button("复制到剪贴板", systemImage: "doc.on.doc") {
                PlatformBridge.copyToPasteboard(filteredText)
                toastManager.showToast(message: "已复制")
            }
            .disabled(filteredLines.isEmpty)
            Divider()
            Button("保存为文件…", systemImage: "square.and.arrow.down", action: exportToFile)
                .disabled(logText.isEmpty)
            Button("使用系统分享…", systemImage: "square.and.arrow.up", action: shareViaSystem)
                .disabled(logText.isEmpty)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(logText.isEmpty)
        .help("导出日志")
    }

    private var clearButton: some View {
        Button {
            showClearConfirm = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.red)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(logText.isEmpty)
        .help("清空日志")
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterChip(
                title: "全部",
                textColor: .white,
                fillStyle: .accent,
                isSelected: selectedLevel == nil
            ) {
                selectedLevel = nil
            }
            ForEach(LogLevel.allCases, id: \.rawValue) { level in
                let isOn = selectedLevel == level
                FilterChip(
                    title: level.displayTitle,
                    textColor: isOn ? .white : level.chipTextColor,
                    fillStyle: isOn ? .tint(level.accentTint) : .glass,
                    isSelected: isOn
                ) {
                    selectedLevel = isOn ? nil : level
                }
            }
            Spacer()
        }
    }

    // MARK: - Table

    private var tableCard: some View {
        VStack(spacing: 0) {
            tableHeader
            if filteredLines.isEmpty {
                ContentUnavailableView(
                    logText.isEmpty ? "暂无日志" : "无匹配日志",
                    systemImage: "doc.text",
                    description: Text(logText.isEmpty ? "应用运行时会在这里记录日志" : "尝试调整筛选或搜索条件")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredLines.enumerated()), id: \.offset) { index, line in
                            LogTableRow(line: line)
                            if index < filteredLines.count - 1 {
                                Divider().foregroundStyle(Color.primary.opacity(0.06))
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("时间")
                .frame(width: 130, alignment: .leading)
            Text("级别")
                .frame(width: 70, alignment: .leading)
            Text("来源")
                .frame(width: 120, alignment: .leading)
            Text("消息")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Color(white: 0.68))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0.94, green: 0.94, blue: 0.95).opacity(0.8))
    }

    // MARK: - Actions

    private func refresh() {
        logText = LogManager.shared.readLogs()
    }

    private func exportToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText, .log]
        panel.nameFieldStringValue = defaultExportFilename
        panel.canCreateDirectories = true
        panel.message = "导出当前筛选后的日志"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try filteredText.write(to: url, atomically: true, encoding: .utf8)
            toastManager.showToast(message: "已导出")
        } catch {
            toastManager.showToast(message: "导出失败")
        }
    }

    private func shareViaSystem() {
        let fileURL = LogManager.shared.logFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            toastManager.showToast(message: "日志文件不存在")
            return
        }
        let picker = NSSharingServicePicker(items: [fileURL])
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else { return }
        picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }

    private var defaultExportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "relay-\(formatter.string(from: Date())).log"
    }

}

// MARK: - Log Table Row

private struct LogTableRow: View {
    let line: String

    private var parsed: ParsedLogLine { ParsedLogLine(line: line) }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(parsed.timestamp.map(String.init) ?? "")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)

            Group {
                if let level = parsed.level {
                    LogLevelBadge(level: level)
                } else {
                    EmptyView()
                }
            }
            .frame(width: 70, alignment: .leading)

            Text(parsed.category.map(String.init) ?? "")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            Text(String(parsed.message))
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(parsed.level?.rowBackground ?? Color.clear)
    }
}

// MARK: - Level Badge

private struct LogLevelBadge: View {
    let level: LogLevel

    var body: some View {
        Text(level.rawValue)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(level.accentTint)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(level.accentTint.opacity(0.12))
            )
    }
}

// MARK: - Parsed log line

/// Splits `[timestamp] [LEVEL] [Category] message` into its component parts.
private struct ParsedLogLine {
    let level: LogLevel?
    let timestamp: Substring?
    let category: Substring?
    let message: Substring

    init(line: String) {
        var remaining = Substring(line)
        let timestamp = Self.consumeBracket(&remaining)
        let levelRaw = Self.consumeBracket(&remaining)
        let category = Self.consumeBracket(&remaining)
        let level = levelRaw.flatMap { LogLevel(rawValue: String($0)) }

        self.timestamp = (level != nil) ? timestamp : nil
        self.level = level
        self.category = (level != nil) ? category : nil
        self.message = (level != nil) ? remaining : Substring(line)
    }

    private static func consumeBracket(_ s: inout Substring) -> Substring? {
        let trimmed = s.drop(while: { $0 == " " })
        guard trimmed.first == "[",
              let close = trimmed.firstIndex(of: "]") else { return nil }
        let inner = trimmed[trimmed.index(after: trimmed.startIndex)..<close]
        s = trimmed[trimmed.index(after: close)...].drop(while: { $0 == " " })
        return inner
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    enum FillStyle {
        case accent
        case tint(Color)
        case glass
    }

    let title: String
    let textColor: Color
    let fillStyle: FillStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(background)
                .overlay(overlay)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        switch fillStyle {
        case .accent:
            Capsule(style: .continuous).fill(Color.accentColor)
        case .tint(let color):
            Capsule(style: .continuous).fill(color)
        case .glass:
            Capsule(style: .continuous).fill(Color.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private var overlay: some View {
        if case .glass = fillStyle {
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        }
    }
}

// MARK: - Level colors

private extension LogLevel {
    /// Tint color used for badges and filter chip selected state.
    /// Matches Pencil design: DEBUG=blue(accent), INFO=green(success), WARN=orange, ERROR=red(danger).
    var accentTint: Color {
        switch self {
        case .debug:   return .blue
        case .info:    return .green
        case .warning: return .orange
        case .error:   return .red
        }
    }

    /// Text color for the filter chip in its unselected state.
    /// Pencil: Info/Debug use neutral greys, Warning/Error keep their tint.
    var chipTextColor: Color {
        switch self {
        case .debug:   return Color(white: 0.68)
        case .info:    return Color(white: 0.53)
        case .warning: return .orange
        case .error:   return .red
        }
    }

    var displayTitle: String {
        switch self {
        case .debug:   return "Debug"
        case .info:    return "Info"
        case .warning: return "Warning"
        case .error:   return "Error"
        }
    }

    var rowBackground: Color {
        switch self {
        case .warning: return Color.orange.opacity(0.06)
        case .error:   return Color.red.opacity(0.06)
        default:       return Color.clear
        }
    }
}
