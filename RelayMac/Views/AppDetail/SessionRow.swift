//
//  SessionRow.swift
//  RelayMac
//

import SwiftUI

struct SessionRow: View {
    let session: Session
    let index: Int
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            indexBadge
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.name).font(.body).bold()
                    if isActive {
                        Label("使用中", systemImage: "checkmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.green)
                            .help("当前应用此会话")
                    }
                }
                if !session.datas.isEmpty {
                    Text(dataSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text(formatDate(session.createTime))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var indexBadge: some View {
        Text("\(index + 1)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Color.secondary, in: Circle())
    }

    private var dataSummary: String {
        let pairs = session.datas.prefix(3).map { d -> String in
            let val: String
            if let raw = d.val?.value {
                val = "\(raw)"
            } else {
                val = "—"
            }
            return "\(d.key)=\(val)"
        }
        let more = session.datas.count > 3 ? " …+\(session.datas.count - 3)" : ""
        return pairs.joined(separator: "  ") + more
    }

    private func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}
