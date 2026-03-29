//
//  LogViewerView.swift
//  NEBox
//
//  Created by Senku on 2026.
//

import SwiftUI

struct LogViewerView: View {
    @State private var logText = ""
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel?
    @State private var showShareSheet = false
    @State private var showClearConfirm = false

    private var filteredLines: [String] {
        let lines = logText.components(separatedBy: "\n").filter { !$0.isEmpty }
        let reversed = lines.reversed().map { $0 }
        return reversed.filter { line in
            let matchesLevel: Bool
            if let level = selectedLevel {
                matchesLevel = line.contains("[\(level.rawValue)]")
            } else {
                matchesLevel = true
            }
            let matchesSearch = searchText.isEmpty || line.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Log list
            if filteredLines.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#9098AD").opacity(0.5))
                    Text("暂无日志")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#9098AD"))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredLines.enumerated()), id: \.offset) { _, line in
                            LogLineView(line: line)
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .background(Color(hex: "#F5F5F7"))
        .navigationTitle("日志")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                }

                Button {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索日志")
        .confirmationDialog("确认清空所有日志？", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("清空", role: .destructive) {
                LogManager.shared.clearLogs()
                logText = ""
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showShareSheet) {
            let url = LogManager.shared.logFileURL
            ShareSheet(items: [url])
        }
        .onAppear {
            logText = LogManager.shared.readLogs()
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "全部", isSelected: selectedLevel == nil) {
                    selectedLevel = nil
                }
                ForEach(LogLevel.allCases, id: \.rawValue) { level in
                    FilterChip(
                        title: level.rawValue,
                        isSelected: selectedLevel == level,
                        color: level.chipColor
                    ) {
                        selectedLevel = selectedLevel == level ? nil : level
                    }
                }
            }
        }
    }
}

// MARK: - Log Line View

private struct LogLineView: View {
    let line: String

    private var level: LogLevel? {
        for l in LogLevel.allCases {
            if line.contains("[\(l.rawValue)]") { return l }
        }
        return nil
    }

    var body: some View {
        Text(line)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(level?.textColor ?? Color(hex: "#1A1918"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(level?.bgColor ?? Color.clear)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = Color(hex: "#002FA7")
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(isSelected ? .white : Color(hex: "#6B7280"))
                .background(isSelected ? color : Color(hex: "#E5E7EB"))
                .clipShape(Capsule())
        }
    }
}

// MARK: - ShareSheet (UIKit bridge)

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Level Colors

private extension LogLevel {
    var chipColor: Color {
        switch self {
        case .debug:   return Color(hex: "#6B7280")
        case .info:    return Color(hex: "#002FA7")
        case .warning: return Color(hex: "#D97706")
        case .error:   return Color(hex: "#DC2626")
        }
    }

    var textColor: Color {
        switch self {
        case .debug:   return Color(hex: "#6B7280")
        case .info:    return Color(hex: "#1A1918")
        case .warning: return Color(hex: "#92400E")
        case .error:   return Color(hex: "#DC2626")
        }
    }

    var bgColor: Color {
        switch self {
        case .debug:   return Color.clear
        case .info:    return Color.clear
        case .warning: return Color(hex: "#FFFBEB")
        case .error:   return Color(hex: "#FEF2F2")
        }
    }
}
