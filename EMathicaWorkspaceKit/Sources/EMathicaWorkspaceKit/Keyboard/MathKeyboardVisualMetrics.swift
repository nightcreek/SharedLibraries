import CoreGraphics
import EMathicaThemeKit
import SwiftUI

public enum MathKeyboardVisualMetrics {
    static func backplateCornerRadius(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.panel.cornerRadius)
    }

    static func shellPadding(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.shellPadding)
    }

    static func backplatePaddingTop(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.backplatePaddingTop)
    }

    static func backplatePaddingHorizontal(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.backplatePaddingHorizontal)
    }

    static func backplatePaddingBottom(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.backplatePaddingBottom)
    }

    static func backplateVisualBleedVertical(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.backplateVisualBleedVertical)
    }

    static func backplateVisualBleedHorizontal(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.backplateVisualBleedHorizontal)
    }

    static func tabSpacing(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.tabSpacing)
    }

    static func rowSpacing(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.rowSpacing)
    }

    static func keySpacing(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.keySpacing)
    }

    static func keyMinHeight(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.keyMinHeight)
    }

    static func tabHeight(for style: MathKeyboardStyle) -> CGFloat {
        CGFloat(style.spacing.tabHeight)
    }

    static let backplateTopHighlightHeight: CGFloat = 1
    static let backplateBottomShadeHeight: CGFloat = 3
    static let shellTopGlowHeight: CGFloat = 8
    static let backplateShadowRadiusDark: CGFloat = 18
    static let backplateShadowRadiusLight: CGFloat = 14
    static let backplateShadowYOffsetDark: CGFloat = 5
    static let backplateShadowYOffsetLight: CGFloat = 4
    static let shellShadowRadiusDark: CGFloat = 8
    static let shellShadowRadiusLight: CGFloat = 7
    static let shellShadowYOffsetDark: CGFloat = 2
    static let shellShadowYOffsetLight: CGFloat = 1
    static let keyShadowRadius: CGFloat = 4
    static let keyShadowYOffset: CGFloat = 1
    static let strokeLineWidth: CGFloat = 0.7
    static let backplateStrokeLineWidth: CGFloat = 0.8

    static func keyRole(for role: MathKeyboardSurfaceRole, style: MathKeyboardStyle, colorScheme: ColorScheme) -> MathKeyboardResolvedKeyRole {
        let dark = colorScheme == .dark
        switch role {
        case .normal:
            return .init(
                fillOpacity: dark ? style.key.normalBackgroundDarkOpacity : style.key.normalBackgroundLightOpacity,
                materialOpacity: dark ? style.key.normalMaterialDarkOpacity : style.key.normalMaterialLightOpacity,
                strokeOpacity: dark ? style.key.normalStrokeDarkOpacity : style.key.normalStrokeLightOpacity,
                highlightOpacity: dark ? style.key.normalHighlightDarkOpacity : style.key.normalHighlightLightOpacity
            )
        case .category:
            return .init(
                fillOpacity: dark ? style.key.categoryBackgroundDarkOpacity : style.key.categoryBackgroundLightOpacity,
                materialOpacity: dark ? style.key.categoryMaterialDarkOpacity : style.key.categoryMaterialLightOpacity,
                strokeOpacity: dark ? style.key.categoryStrokeDarkOpacity : style.key.categoryStrokeLightOpacity,
                highlightOpacity: dark ? style.key.categoryHighlightDarkOpacity : style.key.categoryHighlightLightOpacity
            )
        case .categoryActive:
            return .init(
                fillOpacity: dark ? style.key.categoryActiveBackgroundDarkOpacity : style.key.categoryActiveBackgroundLightOpacity,
                materialOpacity: dark ? style.key.categoryActiveMaterialDarkOpacity : style.key.categoryActiveMaterialLightOpacity,
                strokeOpacity: dark ? style.key.categoryActiveStrokeDarkOpacity : style.key.categoryActiveStrokeLightOpacity,
                highlightOpacity: dark ? style.key.categoryActiveHighlightDarkOpacity : style.key.categoryActiveHighlightLightOpacity
            )
        case .primary:
            return .init(
                fillOpacity: dark ? style.key.accentBackgroundDarkOpacity : style.key.accentBackgroundLightOpacity,
                materialOpacity: dark ? style.key.accentMaterialDarkOpacity : style.key.accentMaterialLightOpacity,
                strokeOpacity: dark ? style.key.accentStrokeDarkOpacity : style.key.accentStrokeLightOpacity,
                highlightOpacity: dark ? style.key.accentHighlightDarkOpacity : style.key.accentHighlightLightOpacity
            )
        }
    }
}

struct MathKeyboardResolvedKeyRole {
    let fillOpacity: Double
    let materialOpacity: Double
    let strokeOpacity: Double
    let highlightOpacity: Double
}

enum MathKeyboardSurfaceRole {
    case normal
    case category
    case categoryActive
    case primary
}
