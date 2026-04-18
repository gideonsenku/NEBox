//
//  WorkbenchSurfaces.swift
//  RelayMac
//
//  Shared surfaces for the redesigned tools (Script Workbench, Data Viewer,
//  …). Backgrounds and panels rely on standard macOS materials; macOS 26's
//  Liquid Glass renders automatically without any simulated overlays.
//

import SwiftUI

struct WorkbenchWindowBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.95, green: 0.96, blue: 0.97),
                Color(red: 0.90, green: 0.92, blue: 0.94),
                Color(red: 0.85, green: 0.87, blue: 0.89).opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.black.opacity(0.02),
                            Color(red: 0.88, green: 0.90, blue: 0.93).opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .ignoresSafeArea()
    }
}

/// Rounded panel using the standard macOS material. No simulated borders or
/// shadows — macOS 26 promotes the material to Liquid Glass automatically.
struct WorkbenchCard<Content: View>: View {
    var cornerRadius: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct WorkbenchOutlinedCard<Content: View>: View {
    var cornerRadius: CGFloat = 14
    var fill: AnyShapeStyle = AnyShapeStyle(.thinMaterial)
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Capsule background for compact secondary buttons / header chips.
struct WorkbenchGlassCapsule: View {
    var body: some View {
        Capsule(style: .continuous).fill(.regularMaterial)
    }
}

/// Small rounded-rect background for count badges and similar inline tags.
struct WorkbenchGlassChip: View {
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.regularMaterial)
    }
}

/// Tinted capsule for a primary action (Run / Save). Uses the system accent
/// by default and stays flat — no extra shadow.
struct WorkbenchAccentCapsule: View {
    var color: Color = .accentColor

    var body: some View {
        Capsule(style: .continuous).fill(color)
    }
}

struct WorkbenchPageScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

struct WorkbenchSectionBlock<Accessory: View, Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
                accessory
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
