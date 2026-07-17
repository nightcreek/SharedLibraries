import Foundation

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

package enum SwiftMathFontRole: Sendable, Equatable {
    case standard
    case handwrittenResult
    case decorative
}

package enum SwiftMathDisplayStyle: Sendable, Equatable {
    case display
    case text
}

package struct SwiftMathVendorColor: Sendable, Equatable {
    package var red: Double
    package var green: Double
    package var blue: Double
    package var alpha: Double

    package init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

package struct SwiftMathRenderedImage: Sendable, Equatable {
    package var pngData: Data
    package var size: CGSize
    package var baseline: Double
    package var cursorAnchor: SwiftMathCursorAnchor?
    package var insertionAnchors: [SwiftMathInsertionAnchor]
    package var placeholderAnchors: [SwiftMathPlaceholderAnchor]
}

public enum SwiftMathCursorContext: Sendable, Equatable {
    case inline
    case numerator
    case denominator
    case radicalDegree
    case radicalRadicand
    case superscript
    case subscriptField
    case unknown
}

package struct SwiftMathCursorAnchor: Sendable, Equatable {
    package var rect: CGRect
    package var x: Double
    package var baseline: Double
    package var ascent: Double
    package var descent: Double
    package var context: SwiftMathCursorContext
}

package struct SwiftMathInsertionAnchor: Sendable, Equatable {
    package var rect: CGRect
    package var x: Double
    package var baseline: Double
    package var ascent: Double
    package var descent: Double
    package var context: SwiftMathCursorContext
}

package struct SwiftMathPlaceholderAnchor: Sendable, Equatable {
    package var rect: CGRect
    package var baseline: Double
    package var ascent: Double
    package var descent: Double
    package var context: SwiftMathCursorContext
}

package struct SwiftMathVendorRenderError: Error, Sendable, Equatable {
    package var domain: String
    package var code: Int
    package var message: String
}

package enum SwiftMathReadOnlyRenderer {
    package static func renderPNG(
        latex: String,
        fontRole: SwiftMathFontRole,
        fontSize: Double,
        foregroundColor: SwiftMathVendorColor,
        displayStyle: SwiftMathDisplayStyle
    ) -> Result<SwiftMathRenderedImage, SwiftMathVendorRenderError> {
        let trimmed = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(
                .init(
                    domain: "EMathicaFormulaDisplayVendor.SwiftMath",
                    code: 1_000,
                    message: "Markup is empty."
                )
            )
        }

        var formatter = MathImage(
            latex: trimmed,
            fontSize: CGFloat(fontSize),
            textColor: makeColor(foregroundColor),
            labelMode: mapDisplayStyle(displayStyle),
            textAlignment: .left
        )
        formatter.font = mapFont(fontRole)

        let (error, image, info) = formatter.asImage()
        if let error {
            return .failure(
                .init(domain: error.domain, code: error.code, message: error.localizedDescription)
            )
        }
        guard let image, let pngData = image.pngDataForVendor() else {
            return .failure(
                .init(
                    domain: "EMathicaFormulaDisplayVendor.SwiftMath",
                    code: 1_001,
                    message: "SwiftMath produced no image output."
                )
            )
        }

        return .success(
            .init(
                pngData: pngData,
                size: image.size,
                baseline: Double(info?.ascent ?? 0),
                cursorAnchor: info?.cursor.map {
                    SwiftMathCursorAnchor(
                        rect: $0.rect,
                        x: Double($0.x),
                        baseline: Double($0.baseline),
                        ascent: Double($0.ascent),
                        descent: Double($0.descent),
                        context: $0.context
                    )
                },
                insertionAnchors: info?.insertionAnchors.map {
                    SwiftMathInsertionAnchor(
                        rect: $0.rect,
                        x: Double($0.x),
                        baseline: Double($0.baseline),
                        ascent: Double($0.ascent),
                        descent: Double($0.descent),
                        context: $0.context
                    )
                } ?? [],
                placeholderAnchors: info?.placeholders.map {
                    SwiftMathPlaceholderAnchor(
                        rect: $0.rect,
                        baseline: Double($0.baseline),
                        ascent: Double($0.ascent),
                        descent: Double($0.descent),
                        context: $0.context
                    )
                } ?? []
            )
        )
    }

    private static func mapFont(_ role: SwiftMathFontRole) -> MathFont {
        switch role {
        case .standard:
            return .xitsFont
        case .handwrittenResult:
            return .eulerFont
        case .decorative:
            return .asanaFont
        }
    }

    private static func mapDisplayStyle(_ style: SwiftMathDisplayStyle) -> MTMathUILabelMode {
        switch style {
        case .display:
            return .display
        case .text:
            return .text
        }
    }

    private static func makeColor(_ color: SwiftMathVendorColor) -> MTColor {
        MTColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(color.alpha)
        )
    }
}

#if os(iOS) || os(visionOS)
private extension UIImage {
    func pngDataForVendor() -> Data? {
        pngData()
    }
}
#elseif os(macOS)
private extension NSImage {
    func pngDataForVendor() -> Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif
