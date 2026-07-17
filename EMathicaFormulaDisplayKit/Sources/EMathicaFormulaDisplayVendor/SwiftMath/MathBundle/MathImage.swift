//
//
// This file is derived from the SwiftMath project.
// Upstream repository: https://github.com/mgriebling/SwiftMath
// Imported from commit: 1d2c90827e9c3908269d810d055fb03b7da5fd53
// Licensed under the MIT License.
//
// Complete license text and local modification records:
// SharedLibraries/ThirdParty/Licenses/SwiftMath/LICENSE.txt
// SharedLibraries/ThirdParty/Licenses/SwiftMath/MODIFICATIONS.md
//
//
//  MathImage.swift
//  
//
//  Created by Peter Tang on 15/9/2023.
//

import Foundation

#if os(iOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public struct MathImage {
    public var font: MathFont = .xitsFont
    public var fontSize: CGFloat
    public var textColor: MTColor

    public var labelMode: MTMathUILabelMode
    public var textAlignment: MTTextAlignment

    public var contentInsets: MTEdgeInsets = MTEdgeInsetsZero
    
    public let latex: String
    
    private(set) var intrinsicContentSize = CGSize.zero

    public init(latex: String, fontSize: CGFloat, textColor: MTColor, labelMode: MTMathUILabelMode = .display, textAlignment: MTTextAlignment = .center) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.labelMode = labelMode
        self.textAlignment = textAlignment
    }
}
extension MathImage {
    public struct CursorLayoutInfo {
        public var rect: CGRect
        public var x: CGFloat
        public var baseline: CGFloat
        public var ascent: CGFloat
        public var descent: CGFloat
        public var context: SwiftMathCursorContext

        public init(
            rect: CGRect,
            x: CGFloat,
            baseline: CGFloat,
            ascent: CGFloat,
            descent: CGFloat,
            context: SwiftMathCursorContext
        ) {
            self.rect = rect
            self.x = x
            self.baseline = baseline
            self.ascent = ascent
            self.descent = descent
            self.context = context
        }
    }

    public struct PlaceholderLayoutInfo {
        public var rect: CGRect
        public var baseline: CGFloat
        public var ascent: CGFloat
        public var descent: CGFloat
        public var context: SwiftMathCursorContext

        public init(
            rect: CGRect,
            baseline: CGFloat,
            ascent: CGFloat,
            descent: CGFloat,
            context: SwiftMathCursorContext
        ) {
            self.rect = rect
            self.baseline = baseline
            self.ascent = ascent
            self.descent = descent
            self.context = context
        }
    }

    public var currentStyle: MTLineStyle {
        switch labelMode {
            case .display: return .display
            case .text: return .text
        }
    }
    private func intrinsicContentSize(_ displayList: MTMathListDisplay) -> CGSize {
        CGSize(width: displayList.width + contentInsets.left + contentInsets.right,
               height: displayList.ascent + displayList.descent + contentInsets.top + contentInsets.bottom)
    }
    public struct LayoutInfo {
        public var ascent: CGFloat = 0
        public var descent: CGFloat = 0
        public var cursor: CursorLayoutInfo?
        public var placeholders: [PlaceholderLayoutInfo]

        public init(
            ascent: CGFloat,
            descent: CGFloat,
            cursor: CursorLayoutInfo? = nil,
            placeholders: [PlaceholderLayoutInfo] = []
        ) {
            self.ascent = ascent
            self.descent = descent
            self.cursor = cursor
            self.placeholders = placeholders
        }
    }
    public mutating func asImage() -> (NSError?, MTImage?, LayoutInfo?) {
        func layoutImage(size: CGSize, displayList: MTMathListDisplay) {
            var textX = CGFloat(0)
            switch self.textAlignment {
                case .left:   textX = contentInsets.left
                case .center: textX = (size.width - contentInsets.left - contentInsets.right - displayList.width) / 2 + contentInsets.left
                case .right:  textX = size.width - displayList.width - contentInsets.right
            }
            let availableHeight = size.height - contentInsets.bottom - contentInsets.top
            
            // center things vertically
            var height = displayList.ascent + displayList.descent
            if height < fontSize/2 {
                height = fontSize/2  // set height to half the font size
            }
            let textY = (availableHeight - height) / 2 + displayList.descent + contentInsets.bottom
            displayList.position = CGPoint(x: textX, y: textY)
        }
        var error: NSError?
        let mtfont: MTFont? = font.mtfont(size: fontSize)

        guard let mathList = MTMathListBuilder.build(fromString: latex, error: &error), error == nil,
              let displayList = MTTypesetter.createLineForMathList(mathList, font: mtfont, style: currentStyle) else {
            return (error, nil, nil)
        }

        intrinsicContentSize = intrinsicContentSize(displayList)
        displayList.textColor = textColor

        let size = intrinsicContentSize.regularized
        layoutImage(size: size, displayList: displayList)
        let cursor = findCursorAnchor(in: displayList, accumulatedOrigin: .zero, context: .inline)
        let placeholders = findPlaceholderAnchors(in: displayList, accumulatedOrigin: .zero, context: .inline)
        
        #if os(iOS) || os(visionOS)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { rendererContext in
                rendererContext.cgContext.saveGState()
                rendererContext.cgContext.concatenate(.flippedVertically(size.height))
                displayList.draw(rendererContext.cgContext)
                rendererContext.cgContext.restoreGState()
            }
            return (nil, image, LayoutInfo(ascent: displayList.ascent, descent: displayList.descent, cursor: cursor, placeholders: placeholders))
        #endif
        #if os(macOS)
            let image = NSImage(size: size, flipped: false) { bounds in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                context.saveGState()
                displayList.draw(context)
                context.restoreGState()
                return true
            }
            return (nil, image, LayoutInfo(ascent: displayList.ascent, descent: displayList.descent, cursor: cursor, placeholders: placeholders))
        #endif
    }

    private func findCursorAnchor(
        in display: MTDisplay,
        accumulatedOrigin: CGPoint,
        context: SwiftMathCursorContext
    ) -> CursorLayoutInfo? {
        if let cursor = display as? MTCursorDisplay {
            let rect = cursor.anchorBounds(at: accumulatedOrigin)
            return CursorLayoutInfo(
                rect: rect,
                x: accumulatedOrigin.x + cursor.position.x,
                baseline: accumulatedOrigin.y + cursor.position.y,
                ascent: cursor.ascent,
                descent: cursor.descent,
                context: context
            )
        }

        if let list = display as? MTMathListDisplay {
            let childOrigin = CGPoint(
                x: accumulatedOrigin.x + list.position.x,
                y: accumulatedOrigin.y + list.position.y
            )
            let childContext: SwiftMathCursorContext
            switch list.type {
            case .superscript:
                childContext = .superscript
            case .ssubscript:
                childContext = .subscriptField
            case .regular:
                childContext = context
            }
            for subDisplay in list.subDisplays {
                if let cursor = findCursorAnchor(
                    in: subDisplay,
                    accumulatedOrigin: childOrigin,
                    context: childContext
                ) {
                    return cursor
                }
            }
            return nil
        }

        if let fraction = display as? MTFractionDisplay {
            if let numerator = fraction.numerator,
               let cursor = findCursorAnchor(
                in: numerator,
                accumulatedOrigin: accumulatedOrigin,
                context: .numerator
               ) {
                return cursor
            }
            if let denominator = fraction.denominator,
               let cursor = findCursorAnchor(
                in: denominator,
                accumulatedOrigin: accumulatedOrigin,
                context: .denominator
               ) {
                return cursor
            }
            return nil
        }

        if let radical = display as? MTRadicalDisplay {
            if let degree = radical.degree,
               let cursor = findCursorAnchor(
                in: degree,
                accumulatedOrigin: accumulatedOrigin,
                context: .radicalDegree
               ) {
                return cursor
            }
            if let radicand = radical.radicand,
               let cursor = findCursorAnchor(
                in: radicand,
                accumulatedOrigin: accumulatedOrigin,
                context: .radicalRadicand
               ) {
                return cursor
            }
            return nil
        }

        if let limits = display as? MTLargeOpLimitsDisplay {
            if let upperLimit = limits.upperLimit,
               let cursor = findCursorAnchor(
                in: upperLimit,
                accumulatedOrigin: accumulatedOrigin,
                context: .superscript
               ) {
                return cursor
            }
            if let lowerLimit = limits.lowerLimit,
               let cursor = findCursorAnchor(
                in: lowerLimit,
                accumulatedOrigin: accumulatedOrigin,
                context: .subscriptField
               ) {
                return cursor
            }
            if let nucleus = limits.nucleus,
               let cursor = findCursorAnchor(
                in: nucleus,
                accumulatedOrigin: accumulatedOrigin,
                context: context
               ) {
                return cursor
            }
            return nil
        }

        if let line = display as? MTLineDisplay, let inner = line.inner {
            return findCursorAnchor(in: inner, accumulatedOrigin: accumulatedOrigin, context: context)
        }

        if let accent = display as? MTAccentDisplay, let accentee = accent.accentee {
            return findCursorAnchor(in: accentee, accumulatedOrigin: accumulatedOrigin, context: context)
        }

        return nil
    }

    private func findPlaceholderAnchors(
        in display: MTDisplay,
        accumulatedOrigin: CGPoint,
        context: SwiftMathCursorContext
    ) -> [PlaceholderLayoutInfo] {
        if let placeholder = display as? MTPlaceholderDisplay {
            return [
                .init(
                    rect: placeholder.anchorBounds(at: accumulatedOrigin),
                    baseline: accumulatedOrigin.y + placeholder.position.y,
                    ascent: placeholder.ascent,
                    descent: placeholder.descent,
                    context: context
                )
            ]
        }

        if let list = display as? MTMathListDisplay {
            let childOrigin = CGPoint(
                x: accumulatedOrigin.x + list.position.x,
                y: accumulatedOrigin.y + list.position.y
            )
            let childContext: SwiftMathCursorContext
            switch list.type {
            case .superscript:
                childContext = .superscript
            case .ssubscript:
                childContext = .subscriptField
            case .regular:
                childContext = context
            }
            return list.subDisplays.flatMap {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: childOrigin, context: childContext)
            }
        }

        if let fraction = display as? MTFractionDisplay {
            return (fraction.numerator.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: .numerator)
            } ?? [])
            + (fraction.denominator.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: .denominator)
            } ?? [])
        }

        if let radical = display as? MTRadicalDisplay {
            return (radical.degree.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: .radicalDegree)
            } ?? [])
            + (radical.radicand.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: .radicalRadicand)
            } ?? [])
        }

        if let limits = display as? MTLargeOpLimitsDisplay {
            return (limits.upperLimit.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: .superscript)
            } ?? [])
            + (limits.lowerLimit.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: .subscriptField)
            } ?? [])
            + (limits.nucleus.map {
                findPlaceholderAnchors(in: $0, accumulatedOrigin: accumulatedOrigin, context: context)
            } ?? [])
        }

        if let line = display as? MTLineDisplay, let inner = line.inner {
            return findPlaceholderAnchors(in: inner, accumulatedOrigin: accumulatedOrigin, context: context)
        }

        if let accent = display as? MTAccentDisplay, let accentee = accent.accentee {
            return findPlaceholderAnchors(in: accentee, accumulatedOrigin: accumulatedOrigin, context: context)
        }

        return []
    }
}
private extension CGAffineTransform {
    static func flippedVertically(_ height: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -height)
        return transform
    }
}
extension CGSize {
    fileprivate var regularized: CGSize {
        CGSize(width: ceil(width), height: ceil(height))
    }
}
