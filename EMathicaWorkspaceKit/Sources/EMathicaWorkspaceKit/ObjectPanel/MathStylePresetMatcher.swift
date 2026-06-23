import EMathicaThemeKit
import EMathicaMathCore
import Foundation

public struct MathStylePresetMatcher {
    public static let epsilon: Double = 1e-9

    public static func colorMatches(_ style: MathStyle, _ color: ColorToken) -> Bool {
        style.colorToken == color.rawValue
    }

    public static func lineWidthMatches(_ style: MathStyle, _ lineWidth: Double) -> Bool {
        abs(style.lineWidth - lineWidth) < epsilon
    }

    public static func opacityMatches(_ style: MathStyle, _ opacity: Double) -> Bool {
        abs(style.opacity - opacity) < epsilon
    }

    public static func pointSizeMatches(_ style: MathStyle, _ pointSize: Double) -> Bool {
        abs(style.pointSize - pointSize) < epsilon
    }

    public static func lineStyleMatches(_ style: MathStyle, _ lineStyle: MathLineStyle) -> Bool {
        style.lineStyle == lineStyle
    }
}
