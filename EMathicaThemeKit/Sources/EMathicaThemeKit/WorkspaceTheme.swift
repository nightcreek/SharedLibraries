import SwiftUI

public struct WorkspaceTheme {
    public init() {}

    public var panelCornerRadius: CGFloat = 24
    public var cardCornerRadius: CGFloat = 18
    public var buttonCornerRadius: CGFloat = 18

    public var panelPadding: CGFloat = 14
    public var gridSpacing: CGFloat = 12
    public var lightPanelOpacity: Double = 0.48
    public var darkPanelOpacity: Double = 0.42
    public var lightStrokeOpacity: Double = 0.08
    public var darkStrokeOpacity: Double = 0.14
    public var lightShadowOpacity: Double = 0.06
    public var darkShadowOpacity: Double = 0.08

    public static var sidePanel: WorkspaceTheme {
        var theme = WorkspaceTheme()
        theme.lightPanelOpacity = 0.18
        theme.darkPanelOpacity = 0.16
        theme.lightStrokeOpacity = 0.06
        theme.darkStrokeOpacity = 0.08
        theme.lightShadowOpacity = 0.035
        theme.darkShadowOpacity = 0.07
        return theme
    }

    public func heroGradient(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color]
        switch scheme {
        case .dark:
            colors = [
                Color(red: 0.05, green: 0.10, blue: 0.22),
                Color(red: 0.12, green: 0.12, blue: 0.32),
                Color(red: 0.18, green: 0.10, blue: 0.32)
            ]
        default:
            colors = [
                Color(red: 0.94, green: 0.97, blue: 1.0),
                Color(red: 0.96, green: 0.94, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 0.99),
                Color(red: 0.92, green: 0.96, blue: 1.0)
            ]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public func panelTint(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color(red: 0.10, green: 0.13, blue: 0.24).opacity(darkPanelOpacity)
        default:
            return Color.white.opacity(lightPanelOpacity)
        }
    }

    public func subtleStroke(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(darkStrokeOpacity)
        default:
            return Color.white.opacity(lightStrokeOpacity)
        }
    }

    public func shadowColor(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.black.opacity(darkShadowOpacity)
        default:
            return Color.black.opacity(lightShadowOpacity)
        }
    }
}

public typealias LiquidGlassTheme = WorkspaceTheme
