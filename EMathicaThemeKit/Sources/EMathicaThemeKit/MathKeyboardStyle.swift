import SwiftUI

public struct MathKeyboardStyle: Equatable, Sendable {
    public var panel: MathKeyboardPanelStyle
    public var key: MathKeyboardKeyStyle
    public var tab: MathKeyboardTabStyle
    public var typography: MathKeyboardTypography
    public var spacing: MathKeyboardSpacing

    public init(
        panel: MathKeyboardPanelStyle,
        key: MathKeyboardKeyStyle,
        tab: MathKeyboardTabStyle,
        typography: MathKeyboardTypography,
        spacing: MathKeyboardSpacing
    ) {
        self.panel = panel
        self.key = key
        self.tab = tab
        self.typography = typography
        self.spacing = spacing
    }

    public static let `default` = MathKeyboardStyle(
        panel: .default,
        key: .default,
        tab: .default,
        typography: .default,
        spacing: .default
    )
}

public struct MathKeyboardPanelStyle: Equatable, Sendable {
    public var cornerRadius: Double
    public var shellBackgroundDarkOpacity: Double
    public var shellBackgroundLightOpacity: Double
    public var shellMaterialDarkOpacity: Double
    public var shellMaterialLightOpacity: Double
    public var shellStrokeDarkOpacity: Double
    public var shellStrokeLightOpacity: Double
    public var shellTopGlowDarkOpacity: Double
    public var shellTopGlowLightOpacity: Double
    public var shellShadowDarkOpacity: Double
    public var shellShadowLightOpacity: Double
    public var backplateBackgroundDarkOpacity: Double
    public var backplateBackgroundLightOpacity: Double
    public var backplateMaterialDarkOpacity: Double
    public var backplateMaterialLightOpacity: Double
    public var backplateStrokeDarkOpacity: Double
    public var backplateStrokeLightOpacity: Double
    public var backplateTopHighlightDarkOpacity: Double
    public var backplateTopHighlightLightOpacity: Double
    public var backplateBottomShadeDarkOpacity: Double
    public var backplateBottomShadeLightOpacity: Double
    public var backplateShadowDarkOpacity: Double
    public var backplateShadowLightOpacity: Double

    public init(
        cornerRadius: Double,
        shellBackgroundDarkOpacity: Double,
        shellBackgroundLightOpacity: Double,
        shellMaterialDarkOpacity: Double,
        shellMaterialLightOpacity: Double,
        shellStrokeDarkOpacity: Double,
        shellStrokeLightOpacity: Double,
        shellTopGlowDarkOpacity: Double,
        shellTopGlowLightOpacity: Double,
        shellShadowDarkOpacity: Double,
        shellShadowLightOpacity: Double,
        backplateBackgroundDarkOpacity: Double,
        backplateBackgroundLightOpacity: Double,
        backplateMaterialDarkOpacity: Double,
        backplateMaterialLightOpacity: Double,
        backplateStrokeDarkOpacity: Double,
        backplateStrokeLightOpacity: Double,
        backplateTopHighlightDarkOpacity: Double,
        backplateTopHighlightLightOpacity: Double,
        backplateBottomShadeDarkOpacity: Double,
        backplateBottomShadeLightOpacity: Double,
        backplateShadowDarkOpacity: Double,
        backplateShadowLightOpacity: Double
    ) {
        self.cornerRadius = cornerRadius
        self.shellBackgroundDarkOpacity = shellBackgroundDarkOpacity
        self.shellBackgroundLightOpacity = shellBackgroundLightOpacity
        self.shellMaterialDarkOpacity = shellMaterialDarkOpacity
        self.shellMaterialLightOpacity = shellMaterialLightOpacity
        self.shellStrokeDarkOpacity = shellStrokeDarkOpacity
        self.shellStrokeLightOpacity = shellStrokeLightOpacity
        self.shellTopGlowDarkOpacity = shellTopGlowDarkOpacity
        self.shellTopGlowLightOpacity = shellTopGlowLightOpacity
        self.shellShadowDarkOpacity = shellShadowDarkOpacity
        self.shellShadowLightOpacity = shellShadowLightOpacity
        self.backplateBackgroundDarkOpacity = backplateBackgroundDarkOpacity
        self.backplateBackgroundLightOpacity = backplateBackgroundLightOpacity
        self.backplateMaterialDarkOpacity = backplateMaterialDarkOpacity
        self.backplateMaterialLightOpacity = backplateMaterialLightOpacity
        self.backplateStrokeDarkOpacity = backplateStrokeDarkOpacity
        self.backplateStrokeLightOpacity = backplateStrokeLightOpacity
        self.backplateTopHighlightDarkOpacity = backplateTopHighlightDarkOpacity
        self.backplateTopHighlightLightOpacity = backplateTopHighlightLightOpacity
        self.backplateBottomShadeDarkOpacity = backplateBottomShadeDarkOpacity
        self.backplateBottomShadeLightOpacity = backplateBottomShadeLightOpacity
        self.backplateShadowDarkOpacity = backplateShadowDarkOpacity
        self.backplateShadowLightOpacity = backplateShadowLightOpacity
    }

    public static let `default` = MathKeyboardPanelStyle(
        cornerRadius: 20,
        shellBackgroundDarkOpacity: 0.008,
        shellBackgroundLightOpacity: 0.018,
        shellMaterialDarkOpacity: 0.22,
        shellMaterialLightOpacity: 0.28,
        shellStrokeDarkOpacity: 0.06,
        shellStrokeLightOpacity: 0.10,
        shellTopGlowDarkOpacity: 0.05,
        shellTopGlowLightOpacity: 0.09,
        shellShadowDarkOpacity: 0.025,
        shellShadowLightOpacity: 0.02,
        backplateBackgroundDarkOpacity: 0.32,
        backplateBackgroundLightOpacity: 0.22,
        backplateMaterialDarkOpacity: 0.46,
        backplateMaterialLightOpacity: 0.54,
        backplateStrokeDarkOpacity: 0.24,
        backplateStrokeLightOpacity: 0.18,
        backplateTopHighlightDarkOpacity: 0.11,
        backplateTopHighlightLightOpacity: 0.14,
        backplateBottomShadeDarkOpacity: 0.08,
        backplateBottomShadeLightOpacity: 0.03,
        backplateShadowDarkOpacity: 0.14,
        backplateShadowLightOpacity: 0.06
    )
}

public struct MathKeyboardKeyStyle: Equatable, Sendable {
    public var cornerRadius: Double
    public var normalBackgroundDarkOpacity: Double
    public var normalBackgroundLightOpacity: Double
    public var categoryBackgroundDarkOpacity: Double
    public var categoryBackgroundLightOpacity: Double
    public var categoryActiveBackgroundDarkOpacity: Double
    public var categoryActiveBackgroundLightOpacity: Double
    public var accentBackgroundDarkOpacity: Double
    public var accentBackgroundLightOpacity: Double
    public var normalStrokeDarkOpacity: Double
    public var normalStrokeLightOpacity: Double
    public var categoryStrokeDarkOpacity: Double
    public var categoryStrokeLightOpacity: Double
    public var categoryActiveStrokeDarkOpacity: Double
    public var categoryActiveStrokeLightOpacity: Double
    public var accentStrokeDarkOpacity: Double
    public var accentStrokeLightOpacity: Double
    public var normalMaterialDarkOpacity: Double
    public var normalMaterialLightOpacity: Double
    public var categoryMaterialDarkOpacity: Double
    public var categoryMaterialLightOpacity: Double
    public var categoryActiveMaterialDarkOpacity: Double
    public var categoryActiveMaterialLightOpacity: Double
    public var accentMaterialDarkOpacity: Double
    public var accentMaterialLightOpacity: Double
    public var normalHighlightDarkOpacity: Double
    public var normalHighlightLightOpacity: Double
    public var categoryHighlightDarkOpacity: Double
    public var categoryHighlightLightOpacity: Double
    public var categoryActiveHighlightDarkOpacity: Double
    public var categoryActiveHighlightLightOpacity: Double
    public var accentHighlightDarkOpacity: Double
    public var accentHighlightLightOpacity: Double
    public var shadowDarkOpacity: Double
    public var shadowLightOpacity: Double

    public init(
        cornerRadius: Double,
        normalBackgroundDarkOpacity: Double,
        normalBackgroundLightOpacity: Double,
        categoryBackgroundDarkOpacity: Double,
        categoryBackgroundLightOpacity: Double,
        categoryActiveBackgroundDarkOpacity: Double,
        categoryActiveBackgroundLightOpacity: Double,
        accentBackgroundDarkOpacity: Double,
        accentBackgroundLightOpacity: Double,
        normalStrokeDarkOpacity: Double,
        normalStrokeLightOpacity: Double,
        categoryStrokeDarkOpacity: Double,
        categoryStrokeLightOpacity: Double,
        categoryActiveStrokeDarkOpacity: Double,
        categoryActiveStrokeLightOpacity: Double,
        accentStrokeDarkOpacity: Double,
        accentStrokeLightOpacity: Double,
        normalMaterialDarkOpacity: Double,
        normalMaterialLightOpacity: Double,
        categoryMaterialDarkOpacity: Double,
        categoryMaterialLightOpacity: Double,
        categoryActiveMaterialDarkOpacity: Double,
        categoryActiveMaterialLightOpacity: Double,
        accentMaterialDarkOpacity: Double,
        accentMaterialLightOpacity: Double,
        normalHighlightDarkOpacity: Double,
        normalHighlightLightOpacity: Double,
        categoryHighlightDarkOpacity: Double,
        categoryHighlightLightOpacity: Double,
        categoryActiveHighlightDarkOpacity: Double,
        categoryActiveHighlightLightOpacity: Double,
        accentHighlightDarkOpacity: Double,
        accentHighlightLightOpacity: Double,
        shadowDarkOpacity: Double,
        shadowLightOpacity: Double
    ) {
        self.cornerRadius = cornerRadius
        self.normalBackgroundDarkOpacity = normalBackgroundDarkOpacity
        self.normalBackgroundLightOpacity = normalBackgroundLightOpacity
        self.categoryBackgroundDarkOpacity = categoryBackgroundDarkOpacity
        self.categoryBackgroundLightOpacity = categoryBackgroundLightOpacity
        self.categoryActiveBackgroundDarkOpacity = categoryActiveBackgroundDarkOpacity
        self.categoryActiveBackgroundLightOpacity = categoryActiveBackgroundLightOpacity
        self.accentBackgroundDarkOpacity = accentBackgroundDarkOpacity
        self.accentBackgroundLightOpacity = accentBackgroundLightOpacity
        self.normalStrokeDarkOpacity = normalStrokeDarkOpacity
        self.normalStrokeLightOpacity = normalStrokeLightOpacity
        self.categoryStrokeDarkOpacity = categoryStrokeDarkOpacity
        self.categoryStrokeLightOpacity = categoryStrokeLightOpacity
        self.categoryActiveStrokeDarkOpacity = categoryActiveStrokeDarkOpacity
        self.categoryActiveStrokeLightOpacity = categoryActiveStrokeLightOpacity
        self.accentStrokeDarkOpacity = accentStrokeDarkOpacity
        self.accentStrokeLightOpacity = accentStrokeLightOpacity
        self.normalMaterialDarkOpacity = normalMaterialDarkOpacity
        self.normalMaterialLightOpacity = normalMaterialLightOpacity
        self.categoryMaterialDarkOpacity = categoryMaterialDarkOpacity
        self.categoryMaterialLightOpacity = categoryMaterialLightOpacity
        self.categoryActiveMaterialDarkOpacity = categoryActiveMaterialDarkOpacity
        self.categoryActiveMaterialLightOpacity = categoryActiveMaterialLightOpacity
        self.accentMaterialDarkOpacity = accentMaterialDarkOpacity
        self.accentMaterialLightOpacity = accentMaterialLightOpacity
        self.normalHighlightDarkOpacity = normalHighlightDarkOpacity
        self.normalHighlightLightOpacity = normalHighlightLightOpacity
        self.categoryHighlightDarkOpacity = categoryHighlightDarkOpacity
        self.categoryHighlightLightOpacity = categoryHighlightLightOpacity
        self.categoryActiveHighlightDarkOpacity = categoryActiveHighlightDarkOpacity
        self.categoryActiveHighlightLightOpacity = categoryActiveHighlightLightOpacity
        self.accentHighlightDarkOpacity = accentHighlightDarkOpacity
        self.accentHighlightLightOpacity = accentHighlightLightOpacity
        self.shadowDarkOpacity = shadowDarkOpacity
        self.shadowLightOpacity = shadowLightOpacity
    }

    public static let `default` = MathKeyboardKeyStyle(
        cornerRadius: 10,
        normalBackgroundDarkOpacity: 0.05,
        normalBackgroundLightOpacity: 0.22,
        categoryBackgroundDarkOpacity: 0.04,
        categoryBackgroundLightOpacity: 0.20,
        categoryActiveBackgroundDarkOpacity: 0.24,
        categoryActiveBackgroundLightOpacity: 0.24,
        accentBackgroundDarkOpacity: 0.26,
        accentBackgroundLightOpacity: 0.24,
        normalStrokeDarkOpacity: 0.16,
        normalStrokeLightOpacity: 0.24,
        categoryStrokeDarkOpacity: 0.13,
        categoryStrokeLightOpacity: 0.26,
        categoryActiveStrokeDarkOpacity: 0.18,
        categoryActiveStrokeLightOpacity: 0.34,
        accentStrokeDarkOpacity: 0.19,
        accentStrokeLightOpacity: 0.36,
        normalMaterialDarkOpacity: 0.12,
        normalMaterialLightOpacity: 0.18,
        categoryMaterialDarkOpacity: 0.10,
        categoryMaterialLightOpacity: 0.16,
        categoryActiveMaterialDarkOpacity: 0.12,
        categoryActiveMaterialLightOpacity: 0.16,
        accentMaterialDarkOpacity: 0.14,
        accentMaterialLightOpacity: 0.18,
        normalHighlightDarkOpacity: 0.12,
        normalHighlightLightOpacity: 0.10,
        categoryHighlightDarkOpacity: 0.10,
        categoryHighlightLightOpacity: 0.09,
        categoryActiveHighlightDarkOpacity: 0.14,
        categoryActiveHighlightLightOpacity: 0.12,
        accentHighlightDarkOpacity: 0.14,
        accentHighlightLightOpacity: 0.12,
        shadowDarkOpacity: 0.08,
        shadowLightOpacity: 0.06
    )
}

public struct MathKeyboardTabStyle: Equatable, Sendable {
    public var cornerRadius: Double
    public var selectedBackgroundOpacity: Double
    public var unselectedBackgroundOpacity: Double
    public var selectedLabelDarkOpacity: Double
    public var selectedLabelLightOpacity: Double
    public var unselectedLabelDarkOpacity: Double
    public var unselectedLabelLightOpacity: Double

    public init(
        cornerRadius: Double,
        selectedBackgroundOpacity: Double,
        unselectedBackgroundOpacity: Double,
        selectedLabelDarkOpacity: Double,
        selectedLabelLightOpacity: Double,
        unselectedLabelDarkOpacity: Double,
        unselectedLabelLightOpacity: Double
    ) {
        self.cornerRadius = cornerRadius
        self.selectedBackgroundOpacity = selectedBackgroundOpacity
        self.unselectedBackgroundOpacity = unselectedBackgroundOpacity
        self.selectedLabelDarkOpacity = selectedLabelDarkOpacity
        self.selectedLabelLightOpacity = selectedLabelLightOpacity
        self.unselectedLabelDarkOpacity = unselectedLabelDarkOpacity
        self.unselectedLabelLightOpacity = unselectedLabelLightOpacity
    }

    public static let `default` = MathKeyboardTabStyle(
        cornerRadius: 12,
        selectedBackgroundOpacity: 0.24,
        unselectedBackgroundOpacity: 0.20,
        selectedLabelDarkOpacity: 0.92,
        selectedLabelLightOpacity: 0.82,
        unselectedLabelDarkOpacity: 0.92,
        unselectedLabelLightOpacity: 0.82
    )
}

public struct MathKeyboardTypography: Equatable, Sendable {
    public var primaryFontSize: Double
    public var templatePrimaryFontSize: Double
    public var secondaryFontSize: Double
    public var tabFontSize: Double

    public init(
        primaryFontSize: Double,
        templatePrimaryFontSize: Double,
        secondaryFontSize: Double,
        tabFontSize: Double
    ) {
        self.primaryFontSize = primaryFontSize
        self.templatePrimaryFontSize = templatePrimaryFontSize
        self.secondaryFontSize = secondaryFontSize
        self.tabFontSize = tabFontSize
    }

    public static let `default` = MathKeyboardTypography(
        primaryFontSize: 15,
        templatePrimaryFontSize: 13,
        secondaryFontSize: 8.5,
        tabFontSize: 13
    )
}

public struct MathKeyboardSpacing: Equatable, Sendable {
    public var shellPadding: Double
    public var backplatePaddingTop: Double
    public var backplatePaddingHorizontal: Double
    public var backplatePaddingBottom: Double
    public var backplateVisualBleedVertical: Double
    public var backplateVisualBleedHorizontal: Double
    public var tabSpacing: Double
    public var rowSpacing: Double
    public var keySpacing: Double
    public var keyMinHeight: Double
    public var tabHeight: Double

    public init(
        shellPadding: Double,
        backplatePaddingTop: Double,
        backplatePaddingHorizontal: Double,
        backplatePaddingBottom: Double,
        backplateVisualBleedVertical: Double,
        backplateVisualBleedHorizontal: Double,
        tabSpacing: Double,
        rowSpacing: Double,
        keySpacing: Double,
        keyMinHeight: Double,
        tabHeight: Double
    ) {
        self.shellPadding = shellPadding
        self.backplatePaddingTop = backplatePaddingTop
        self.backplatePaddingHorizontal = backplatePaddingHorizontal
        self.backplatePaddingBottom = backplatePaddingBottom
        self.backplateVisualBleedVertical = backplateVisualBleedVertical
        self.backplateVisualBleedHorizontal = backplateVisualBleedHorizontal
        self.tabSpacing = tabSpacing
        self.rowSpacing = rowSpacing
        self.keySpacing = keySpacing
        self.keyMinHeight = keyMinHeight
        self.tabHeight = tabHeight
    }

    public static let `default` = MathKeyboardSpacing(
        shellPadding: 8,
        backplatePaddingTop: 12,
        backplatePaddingHorizontal: 9,
        backplatePaddingBottom: 10,
        backplateVisualBleedVertical: 5,
        backplateVisualBleedHorizontal: 3,
        tabSpacing: 6,
        rowSpacing: 7,
        keySpacing: 7,
        keyMinHeight: 40,
        tabHeight: 36
    )
}
