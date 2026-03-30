//
//  SwipeActionRow.swift
//  NEBox
//
//  Created by Senku on 2024.
//

import SwiftUI

struct SwipeAction {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct SwipeActionRow<Content: View>: View {
    let rowId: String
    let content: () -> Content
    let actions: [SwipeAction]
    let onTap: () -> Void
    @Binding var openRowId: String?

    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragStartOffset: CGFloat = 0
    // Tracks whether a meaningful horizontal drag occurred in the current gesture.
    // Reset synchronously at drag-start to avoid asyncAfter timing issues (H2 fix).
    @State private var didSwipe = false

    private let buttonWidth: CGFloat = 72
    private var totalActionWidth: CGFloat { CGFloat(actions.count) * buttonWidth }

    private var isOpen: Bool { openRowId == rowId }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Main content
                content()
                    .frame(width: geo.size.width)
                    .background(Color.bgCard)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isOpen {
                            close()
                        } else if !didSwipe {
                            onTap()
                        }
                    }

                // Action buttons (immediately to the right of content)
                ForEach(actions.indices, id: \.self) { index in
                    Button {
                        let action = actions[index].action
                        close()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            action()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: actions[index].icon)
                                .font(.system(size: 16))
                            Text(actions[index].title)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: buttonWidth)
                        .frame(maxHeight: .infinity)
                        .background(actions[index].color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .offset(x: offset)
            .highPriorityGesture(swipeGesture)
        }
        .frame(height: 56)
        .clipped()
        // H1 fix: reconcile offset with openRowId when binding changes externally
        .onChange(of: openRowId) { newValue in
            if newValue == rowId && offset == 0 {
                // Another source opened us — sync offset
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = -totalActionWidth
                }
            } else if newValue != rowId && offset != 0 {
                // Another row opened — close ourselves
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                }
            }
        }
        // H1 fix: reconcile on appear (handles view recreation with stale openRowId)
        .onAppear {
            if isOpen && offset == 0 {
                offset = -totalActionWidth
            } else if !isOpen && offset != 0 {
                offset = 0
            }
        }
    }

    // H3 fix: use .highPriorityGesture + higher minimumDistance to reduce ScrollView conflict
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                if !isDragging {
                    // H3: stricter horizontal check to avoid stealing vertical scrolls
                    guard horizontal > vertical * 2.0 else { return }
                    isDragging = true
                    didSwipe = true  // H2 fix: set synchronously, no asyncAfter
                    dragStartOffset = offset
                }

                let target = dragStartOffset + value.translation.width
                offset = min(0, max(-totalActionWidth - 20, target))
            }
            .onEnded { value in
                isDragging = false

                guard didSwipe else { return }

                let velocity = value.predictedEndTranslation.width - value.translation.width

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isOpen {
                        if value.translation.width > totalActionWidth * 0.25 || velocity > 100 {
                            offset = 0
                            openRowId = nil
                        } else {
                            offset = -totalActionWidth
                        }
                    } else {
                        if -value.translation.width > totalActionWidth * 0.3 || velocity < -100 {
                            offset = -totalActionWidth
                            openRowId = rowId
                        } else {
                            offset = 0
                        }
                    }
                }

                // H2 fix: reset didSwipe after animation settles (synchronous scheduling)
                DispatchQueue.main.async {
                    didSwipe = false
                }
            }
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            openRowId = nil
        }
    }
}
