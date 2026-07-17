import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaDisplayView: View {
    private enum Storage {
        case legacy(plan: FormulaRenderPlan, showsCursor: Bool, showsDebugFrames: Bool)
        case swiftMath(
            snapshot: FormulaSwiftMathSnapshot?,
            error: FormulaSwiftMathRenderError?,
            showsCursor: Bool,
            showsPlaceholderBounds: Bool,
            onTapInsertionID: ((FormulaInsertionID) -> Void)?
        )
    }

    private let storage: Storage
    private let style: FormulaDisplayStyle

    public init(markup: FormulaDisplayMarkup) {
        self.init(
            markup: markup,
            style: .default,
            options: .default,
            metrics: .default
        )
    }

    public init(document: FormulaDisplayDocument) {
        self.init(
            document: document,
            style: .default,
            options: .default,
            metrics: .default
        )
    }

    public init(rawValue: String) {
        self.init(
            rawValue: rawValue,
            style: .default,
            options: .default,
            metrics: .default
        )
    }

    public init(plan: FormulaRenderPlan) {
        self.init(plan: plan, style: .default)
    }

    public init(
        markup: FormulaDisplayMarkup,
        style: FormulaDisplayStyle = .default,
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default,
        onTapInsertionID: ((FormulaInsertionID) -> Void)? = nil
    ) {
        self.style = style
        if FormulaDisplayContentInspector.isEffectivelyEmpty(markup) {
            self.storage = .swiftMath(
                snapshot: nil,
                error: nil,
                showsCursor: options.cursorVisible,
                showsPlaceholderBounds: options.debugFramesEnabled,
                onTapInsertionID: onTapInsertionID
            )
            return
        }
        let color = style.textColor.resolvedFormulaRGBA()
        switch FormulaDisplayContentResolver.resolve(
            markup: markup,
            options: options,
            metrics: metrics,
            foregroundColor: color
        ) {
        case .legacy(let plan):
            self.storage = .legacy(
                plan: plan,
                showsCursor: options.cursorVisible,
                showsDebugFrames: options.debugFramesEnabled
            )
        case .swiftMath(let snapshot):
            self.storage = .swiftMath(
                snapshot: snapshot,
                error: nil,
                showsCursor: options.cursorVisible,
                showsPlaceholderBounds: options.debugFramesEnabled,
                onTapInsertionID: onTapInsertionID
            )
        case .swiftMathError(let error):
            self.storage = .swiftMath(
                snapshot: nil,
                error: error,
                showsCursor: options.cursorVisible,
                showsPlaceholderBounds: options.debugFramesEnabled,
                onTapInsertionID: onTapInsertionID
            )
        }
    }

    public init(
        document: FormulaDisplayDocument,
        style: FormulaDisplayStyle = .default,
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default,
        onTapInsertionID: ((FormulaInsertionID) -> Void)? = nil
    ) {
        self.style = style
        if FormulaDisplayContentInspector.isEffectivelyEmpty(document) {
            self.storage = .swiftMath(
                snapshot: nil,
                error: nil,
                showsCursor: options.cursorVisible,
                showsPlaceholderBounds: options.debugFramesEnabled,
                onTapInsertionID: onTapInsertionID
            )
            return
        }
        let color = style.textColor.resolvedFormulaRGBA()
        switch FormulaDisplayContentResolver.resolve(
            document: document,
            options: options,
            metrics: metrics,
            foregroundColor: color
        ) {
        case .legacy(let plan):
            self.storage = .legacy(
                plan: plan,
                showsCursor: options.cursorVisible,
                showsDebugFrames: options.debugFramesEnabled
            )
        case .swiftMath(let snapshot):
            self.storage = .swiftMath(
                snapshot: snapshot,
                error: nil,
                showsCursor: options.cursorVisible,
                showsPlaceholderBounds: options.debugFramesEnabled,
                onTapInsertionID: onTapInsertionID
            )
        case .swiftMathError(let error):
            self.storage = .swiftMath(
                snapshot: nil,
                error: error,
                showsCursor: options.cursorVisible,
                showsPlaceholderBounds: options.debugFramesEnabled,
                onTapInsertionID: onTapInsertionID
            )
        }
    }

    public init(
        rawValue: String,
        style: FormulaDisplayStyle = .default,
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default,
        onTapInsertionID: ((FormulaInsertionID) -> Void)? = nil
    ) {
        self.init(
            markup: FormulaDisplayMarkup(rawValue: rawValue),
            style: style,
            options: options,
            metrics: metrics,
            onTapInsertionID: onTapInsertionID
        )
    }

    public init(
        plan: FormulaRenderPlan,
        style: FormulaDisplayStyle = .default,
        showsCursor: Bool = true,
        showsDebugFrames: Bool = false
    ) {
        self.storage = .legacy(
            plan: plan,
            showsCursor: showsCursor,
            showsDebugFrames: showsDebugFrames
        )
        self.style = style
    }

    public var body: some View {
        switch storage {
        case .legacy(let plan, let showsCursor, let showsDebugFrames):
            FormulaRenderPlanView(
                plan: plan,
                style: style,
                showsCursor: showsCursor,
                showsDebugFrames: showsDebugFrames
            )
        case .swiftMath(let snapshot, let error, let showsCursor, let showsPlaceholderBounds, let onTapInsertionID):
            FormulaSwiftMathSnapshotView(
                snapshot: snapshot,
                error: error,
                style: style,
                showsCursor: showsCursor,
                showsPlaceholderBounds: showsPlaceholderBounds,
                onTapInsertionID: onTapInsertionID
            )
        }
    }
}
