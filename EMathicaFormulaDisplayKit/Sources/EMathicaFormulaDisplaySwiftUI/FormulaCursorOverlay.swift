import EMathicaFormulaDisplayCore
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct FormulaCursorOverlay: View {
    let rect: CGRect
    let color: Color
    let opacity: Double

    init(rect: CGRect, color: Color, opacity: Double) {
        self.rect = rect
        self.color = color
        self.opacity = opacity
    }

    init(state: FormulaCursorState, color: Color, opacity: Double) {
        self.init(
            rect: FormulaCursorOverlay.cursorVisualRect(for: state),
            color: color,
            opacity: opacity
        )
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: rect.width,
                height: rect.height
            )
            .offset(
                x: rect.minX,
                y: rect.minY
            )
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.18), value: opacity)
            .accessibilityHidden(true)
    }

    static func cursorRect(for state: FormulaCursorState) -> CGRect {
        FormulaCursorVisualMetricsPolicy.legacyCursorRect(for: state.insertionPoint)
    }

    static func cursorVisualRect(for state: FormulaCursorState) -> CGRect {
        FormulaCursorVisualMetricsPolicy.visualCursorRect(for: state.insertionPoint)
    }
}

private enum FormulaCursorVisualMetricsPolicy {
    static func legacyCursorRect(for anchor: FormulaCursorAnchor) -> CGRect {
        let topExtent = max(anchor.descent, 0)
        let bottomExtent = max(anchor.ascent, 0)
        let baseHeight = max(topExtent + bottomExtent, 1)
        let profile = profile(for: anchor.context)

        var visualTop = topExtent * profile.topScale
        var visualBottom = bottomExtent * profile.bottomScale
        let scaledHeight = max(visualTop + visualBottom, 1)
        let minimumHeight = max(profile.minimumHeight, baseHeight * profile.minimumHeightRatio)

        if scaledHeight < minimumHeight {
            let extra = minimumHeight - scaledHeight
            visualTop += extra * profile.topGrowthBias
            visualBottom += extra * (1 - profile.topGrowthBias)
        }

        let preferredWidth = round(profile.strokeWidth * 2) / 2
        let x = CGFloat(anchor.x + max((anchor.rect.size.width - preferredWidth) / 2, 0))
        let y = CGFloat(anchor.baseline - visualTop + profile.verticalOffset)

        return CGRect(
            x: x,
            y: y,
            width: CGFloat(preferredWidth),
            height: CGFloat(max(visualTop + visualBottom, minimumHeight))
        )
    }

    static func visualCursorRect(for anchor: FormulaCursorAnchor) -> CGRect {
        let rawRect = CGRect(
            x: CGFloat(anchor.rect.minX),
            y: CGFloat(anchor.rect.minY),
            width: CGFloat(anchor.rect.size.width),
            height: CGFloat(anchor.rect.size.height)
        )
        let targetWidth = max(2.0, rawRect.width)
        let baseTop = CGFloat(anchor.baseline - anchor.ascent)
        let baseBottom = CGFloat(anchor.baseline + anchor.descent)
        let targetHeight = max(baseBottom - baseTop, 16)
        let rawCenterX = rawRect.midX
        let rawCenterY = (baseTop + baseBottom) / 2

        return CGRect(
            x: pixelAlign(rawCenterX - targetWidth / 2),
            y: pixelAlign(rawCenterY - targetHeight / 2),
            width: pixelAlign(targetWidth),
            height: pixelAlign(targetHeight)
        )
    }

    private static func pixelAlign(_ value: CGFloat) -> CGFloat {
        #if canImport(UIKit)
        let scale = UIScreen.main.scale
        #elseif canImport(AppKit)
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        #else
        let scale = 2.0
        #endif
        return (value * scale).rounded() / scale
    }

    private static func profile(for context: FormulaCursorContext) -> CursorVisualProfile {
        switch context {
        case .inline, .unknown:
            return .init(
                topScale: 1.10,
                bottomScale: 1.05,
                minimumHeightRatio: 1.10,
                minimumHeight: 14,
                topGrowthBias: 0.55,
                verticalOffset: -0.2,
                strokeWidth: 2
            )
        case .superscript:
            return .init(
                topScale: 1.35,
                bottomScale: 0.90,
                minimumHeightRatio: 1.30,
                minimumHeight: 12,
                topGrowthBias: 0.80,
                verticalOffset: -1.2,
                strokeWidth: 1.5
            )
        case .subscriptField:
            return .init(
                topScale: 0.90,
                bottomScale: 1.35,
                minimumHeightRatio: 1.30,
                minimumHeight: 12,
                topGrowthBias: 0.20,
                verticalOffset: 1.0,
                strokeWidth: 1.5
            )
        case .numerator:
            return .init(
                topScale: 1.25,
                bottomScale: 0.82,
                minimumHeightRatio: 1.18,
                minimumHeight: 12,
                topGrowthBias: 0.76,
                verticalOffset: -1.0,
                strokeWidth: 1.5
            )
        case .denominator:
            return .init(
                topScale: 0.82,
                bottomScale: 1.25,
                minimumHeightRatio: 1.18,
                minimumHeight: 12,
                topGrowthBias: 0.24,
                verticalOffset: 1.0,
                strokeWidth: 1.5
            )
        case .radicalDegree:
            return .init(
                topScale: 1.20,
                bottomScale: 0.95,
                minimumHeightRatio: 1.20,
                minimumHeight: 11,
                topGrowthBias: 0.72,
                verticalOffset: -0.8,
                strokeWidth: 1.5
            )
        case .radicalRadicand:
            return .init(
                topScale: 0.92,
                bottomScale: 1.20,
                minimumHeightRatio: 1.18,
                minimumHeight: 12,
                topGrowthBias: 0.35,
                verticalOffset: 0.5,
                strokeWidth: 1.5
            )
        }
    }
}

private struct CursorVisualProfile {
    let topScale: Double
    let bottomScale: Double
    let minimumHeightRatio: Double
    let minimumHeight: Double
    let topGrowthBias: Double
    let verticalOffset: Double
    let strokeWidth: Double
}
