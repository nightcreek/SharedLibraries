import EMathicaFormulaDisplayCore
import Foundation

enum FormulaReadOnlyDisplayResolvedMode: Equatable {
    case formula(
        document: FormulaDisplayDocument?,
        rawValue: String,
        options: FormulaDisplayOptions,
        fallbackReason: FormulaDisplayFallbackReason?
    )
    case plainText(text: String, fallbackReason: FormulaDisplayFallbackReason)
}

enum FormulaReadOnlyDisplayResolver {
    @MainActor
    private static var cache: [FormulaReadOnlyDisplayCacheKey: FormulaReadOnlyDisplayResolvedMode] = [:]

    @MainActor
    static func resolve(
        rawValue: String,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaReadOnlyDisplayResolvedMode {
        resolve(
            surface: .objectPanel,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline,
            configuration: configuration
        )
    }

    @MainActor
    static func resolve(
        surface: FormulaDisplaySurface,
        document: FormulaDisplayDocument,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaReadOnlyDisplayResolvedMode {
        let rawValue = FormulaDisplayDocumentSerializer.serialize(document)
        let key = FormulaReadOnlyDisplayCacheKey(
            surface: surface,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline,
            configuration: configuration
        )
        if let cached = cache[key], case .formula(_, let cachedRawValue, let options, let fallbackReason) = cached, cachedRawValue == rawValue {
            return .formula(document: document, rawValue: rawValue, options: options, fallbackReason: fallbackReason)
        } else if let cached = cache[key] {
            return cached
        }

        let resolved = resolveUncached(
            surface: surface,
            document: document,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline,
            configuration: configuration
        )
        cache[key] = resolved
        return resolved
    }

    @MainActor
    static func resolve(
        surface: FormulaDisplaySurface,
        rawValue: String,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaReadOnlyDisplayResolvedMode {
        let key = FormulaReadOnlyDisplayCacheKey(
            surface: surface,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline,
            configuration: configuration
        )
        if let cached = cache[key] {
            return cached
        }

        let resolved = resolveUncached(
            surface: surface,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline,
            configuration: configuration
        )
        cache[key] = resolved
        return resolved
    }

    static func resolveUncached(
        rawValue: String,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaReadOnlyDisplayResolvedMode {
        resolveUncached(
            surface: .objectPanel,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline,
            configuration: configuration
        )
    }

    static func resolveUncached(
        surface: FormulaDisplaySurface,
        document: FormulaDisplayDocument,
        rawValue: String,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaReadOnlyDisplayResolvedMode {
        let trimmedMarkup = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedFallback = sanitizePlainText(fallbackText)
        let trimmedFallback = sanitizedFallback.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedMarkupText = sanitizePlainText(rawValue)
        guard !trimmedMarkup.isEmpty else {
            if !trimmedFallback.isEmpty {
                return .plainText(text: sanitizedFallback, fallbackReason: .emptyOutput)
            }
            return .plainText(text: "", fallbackReason: .emptyOutput)
        }

        let metrics = makeMetrics(surface: surface, fontSize: fontSize, minHeight: minHeight)
        let preferredOptions = FormulaDisplayOptions(
            debugFramesEnabled: false,
            cursorVisible: false,
            renderingBackend: configuration.backend,
            fontRole: configuration.fontRole
        )

        switch configuration.backend {
        case .legacy:
            switch FormulaReadOnlyRenderProbe.measure(document: document, options: preferredOptions, metrics: metrics) {
            case .success:
                return .formula(document: document, rawValue: rawValue, options: preferredOptions, fallbackReason: nil)
            case .failure(let reason, _):
                return .plainText(
                    text: !trimmedFallback.isEmpty ? sanitizedFallback : sanitizedMarkupText,
                    fallbackReason: reason
                )
            }
        case .swiftMath:
            switch FormulaReadOnlyRenderProbe.measure(document: document, options: preferredOptions, metrics: metrics) {
            case .success:
                return .formula(document: document, rawValue: rawValue, options: preferredOptions, fallbackReason: nil)
            case .failure(let reason, _):
                #if DEBUG
                return .formula(document: document, rawValue: rawValue, options: preferredOptions, fallbackReason: reason)
                #else
                return .plainText(
                    text: !trimmedFallback.isEmpty ? sanitizedFallback : sanitizedMarkupText,
                    fallbackReason: reason
                )
                #endif
            }
        }
    }

    static func resolveUncached(
        surface: FormulaDisplaySurface,
        rawValue: String,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaReadOnlyDisplayResolvedMode {
        let trimmedMarkup = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedFallback = sanitizePlainText(fallbackText)
        let trimmedFallback = sanitizedFallback.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedMarkupText = sanitizePlainText(rawValue)
        guard !trimmedMarkup.isEmpty else {
            if !trimmedFallback.isEmpty {
                return .plainText(text: sanitizedFallback, fallbackReason: .emptyOutput)
            }
            return .plainText(text: "", fallbackReason: .emptyOutput)
        }

        let metrics = makeMetrics(surface: surface, fontSize: fontSize, minHeight: minHeight)
        let preferredOptions = FormulaDisplayOptions(
            debugFramesEnabled: false,
            cursorVisible: false,
            renderingBackend: configuration.backend,
            fontRole: configuration.fontRole
        )
        let markup = EMathicaFormulaDisplayCore.FormulaDisplayMarkup(rawValue: String(rawValue))

        switch configuration.backend {
        case .legacy:
            switch FormulaReadOnlyRenderProbe.measure(markup: markup, options: preferredOptions, metrics: metrics) {
            case .success:
                return .formula(document: nil, rawValue: rawValue, options: preferredOptions, fallbackReason: nil)
            case .failure(let reason, _):
                return .plainText(
                    text: !trimmedFallback.isEmpty ? sanitizedFallback : sanitizedMarkupText,
                    fallbackReason: reason
                )
            }
        case .swiftMath:
            switch FormulaReadOnlyRenderProbe.measure(markup: markup, options: preferredOptions, metrics: metrics) {
            case .success:
                return .formula(document: nil, rawValue: rawValue, options: preferredOptions, fallbackReason: nil)
            case .failure(let reason, _):
                #if DEBUG
                return .formula(document: nil, rawValue: rawValue, options: preferredOptions, fallbackReason: reason)
                #else
                return .plainText(
                    text: !trimmedFallback.isEmpty ? sanitizedFallback : sanitizedMarkupText,
                    fallbackReason: reason
                )
                #endif
            }
        }
    }

    static func makeMetrics(
        fontSize: CGFloat,
        minHeight: CGFloat
    ) -> FormulaLayoutMetrics {
        makeMetrics(surface: .objectPanel, fontSize: fontSize, minHeight: minHeight)
    }

    static func makeMetrics(
        surface: FormulaDisplaySurface,
        fontSize: CGFloat,
        minHeight: CGFloat
    ) -> FormulaLayoutMetrics {
        switch surface {
        case .objectPanel, .inspector, .editorPreview, .notebook, .export:
            return .init(
                baseFontSize: fontSize,
                scriptScale: 0.66,
                minimumFontSize: max(8, fontSize * 0.58),
                operatorSpacing: 1.6,
                functionSpacing: 1.35,
                fractionHorizontalPadding: 2.2,
                fractionVerticalGap: 1.9,
                fractionLineThickness: 0.85,
                sqrtHorizontalPadding: 1.55,
                sqrtOverlineGap: 1.2,
                scriptVerticalRaise: max(5.2, fontSize * 0.52),
                subscriptVerticalDrop: max(3.8, fontSize * 0.34),
                delimiterHorizontalPadding: 1.9,
                absoluteValueStrokeWidth: 0.65,
                rawFallbackPadding: 1.5,
                cursorWidth: 1.2,
                placeholderWidth: max(9.0, fontSize * 0.58),
                placeholderHeight: max(12.4, fontSize * 0.87),
                minimumBoxSize: .init(width: max(11, fontSize * 0.76), height: max(Double(minHeight), fontSize * 1.02))
            )
        }
    }

    static func sanitizePlainText(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\cursor{}"#, with: "")
            .replacingOccurrences(of: #"\cursor"#, with: "")
            .replacingOccurrences(of: #"\placeholder{}"#, with: "")
            .replacingOccurrences(of: #"\placeholder"#, with: "")
    }
}

typealias ObjectPanelFormulaResolvedMode = FormulaReadOnlyDisplayResolvedMode
typealias ObjectPanelFormulaDisplayResolver = FormulaReadOnlyDisplayResolver

private struct FormulaReadOnlyDisplayCacheKey: Hashable {
    var surface: FormulaDisplaySurface
    var rawValue: String
    var fallbackText: String
    var fontSize: CGFloat
    var minHeight: CGFloat
    var allowsMultiline: Bool
    var configuration: FormulaRenderingConfiguration
}
