//
//  MacJavaScriptCodeEditor.swift
//  RelayMac
//

import AppKit
import Highlighter
import SwiftUI

struct MacJavaScriptCodeEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = AppearanceAwareTextView(frame: .zero, textContainer: textContainer)
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.usesAdaptiveColorMappingForDarkAppearance = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.string = text
        textView.delegate = context.coordinator
        textView.onAppearanceChange = { [weak coordinator = context.coordinator] appearance in
            coordinator?.applyTheme(for: appearance)
        }

        let scrollView = AppearanceAwareScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor
        scrollView.documentView = textView
        scrollView.onAppearanceChange = { [weak coordinator = context.coordinator] appearance in
            coordinator?.applyTheme(for: appearance)
        }

        context.coordinator.textView = textView
        context.coordinator.applyTheme(for: scrollView.effectiveAppearance)
        context.coordinator.rehighlightText()
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.applyTheme(for: nsView.effectiveAppearance)
        guard let textView = context.coordinator.textView else { return }
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
            context.coordinator.rehighlightText(preserving: selectedRange)
        }
    }

    final class AppearanceAwareScrollView: NSScrollView {
        var onAppearanceChange: ((NSAppearance) -> Void)?

        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()
            onAppearanceChange?(effectiveAppearance)
        }
    }

    final class AppearanceAwareTextView: NSTextView {
        var onAppearanceChange: ((NSAppearance) -> Void)?

        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()
            onAppearanceChange?(effectiveAppearance)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?
        private let highlighter = Highlighter()
        private let codeFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        private var isApplyingHighlight = false
        private var currentThemeName: String?

        init(text: Binding<String>) {
            _text = text
            highlighter?.ignoreIllegals = true
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingHighlight else { return }
            text = textView?.string ?? ""
            rehighlightText()
        }

        func applyTheme(for appearance: NSAppearance) {
            guard let textView else { return }
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let themeName = isDark ? "atom-one-dark" : "atom-one-light"
            let themeDidChange: Bool
            if currentThemeName != themeName {
                themeDidChange = highlighter?.setTheme(themeName, withFont: codeFont.fontName, ofSize: codeFont.pointSize) == true
                if themeDidChange {
                    currentThemeName = themeName
                }
            } else {
                themeDidChange = false
            }

            let background = highlighter?.theme.themeBackgroundColour ?? (isDark ? .black : .white)
            let foreground = isDark ? NSColor(calibratedRed: 0.79, green: 0.82, blue: 0.85, alpha: 1) : NSColor(calibratedWhite: 0.2, alpha: 1)
            textView.backgroundColor = background
            textView.textColor = foreground
            textView.insertionPointColor = foreground
            textView.typingAttributes = [
                .font: codeFont,
                .foregroundColor: foreground
            ]
            textView.enclosingScrollView?.backgroundColor = background

            if themeDidChange {
                DispatchQueue.main.async { [weak self] in
                    self?.rehighlightText()
                }
            } else {
                textView.needsDisplay = true
                textView.enclosingScrollView?.needsDisplay = true
            }
        }

        func rehighlightText(preserving selectedRange: NSRange? = nil) {
            guard let textView, !isApplyingHighlight else { return }
            let source = textView.string
            let range = selectedRange ?? textView.selectedRange()
            let storage = textView.textStorage

            isApplyingHighlight = true
            defer {
                isApplyingHighlight = false
            }

            storage?.beginEditing()
            storage?.setAttributedString(NSAttributedString())

            if let highlighted = highlighter?.highlight(source, as: "javascript", doFastRender: false) {
                storage?.append(highlighted)
            } else {
                storage?.append(
                    NSAttributedString(
                        string: source,
                        attributes: [
                            .font: codeFont,
                            .foregroundColor: textView.textColor ?? NSColor.labelColor
                        ]
                    )
                )
            }
            storage?.endEditing()

            let safeLocation = min(range.location, (textView.string as NSString).length)
            let safeLength = min(range.length, (textView.string as NSString).length - safeLocation)
            textView.setSelectedRange(NSRange(location: safeLocation, length: safeLength))
        }
    }
}
