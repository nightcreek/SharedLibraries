import Foundation

public struct FormulaDisplayDocument: Equatable, Sendable {
    public var root: FormulaDisplayNode

    public init(root: FormulaDisplayNode) {
        self.root = root
    }
}

public enum FormulaPlaceholderWidthPolicy: String, Equatable, Sendable {
    case quad
}

public enum FormulaCursorSpacingPolicy: String, Equatable, Sendable {
    case medium
    case thick
}

public struct FormulaDisplayPlaceholderToken: Equatable, Sendable {
    public var id: String
    public var sourcePath: [String]
    public var fieldIdentity: String?
    public var kind: String
    public var widthPolicy: FormulaPlaceholderWidthPolicy

    public init(
        id: String,
        sourcePath: [String],
        fieldIdentity: String? = nil,
        kind: String = "emptyField",
        widthPolicy: FormulaPlaceholderWidthPolicy = .quad
    ) {
        self.id = id
        self.sourcePath = sourcePath
        self.fieldIdentity = fieldIdentity
        self.kind = kind
        self.widthPolicy = widthPolicy
    }
}

public extension FormulaDisplayPlaceholderToken {
    static var anonymous: Self {
        .init(id: "placeholder:anonymous", sourcePath: [])
    }
}

public struct FormulaDisplayCursorToken: Equatable, Sendable {
    public var id: String
    public var sourcePath: [String]
    public var fieldIdentity: String?
    public var offset: Int
    public var spacingPolicy: FormulaCursorSpacingPolicy

    public init(
        id: String,
        sourcePath: [String],
        fieldIdentity: String? = nil,
        offset: Int,
        spacingPolicy: FormulaCursorSpacingPolicy = .medium
    ) {
        self.id = id
        self.sourcePath = sourcePath
        self.fieldIdentity = fieldIdentity
        self.offset = offset
        self.spacingPolicy = spacingPolicy
    }
}

public extension FormulaDisplayCursorToken {
    static var anonymous: Self {
        .init(id: "cursor:anonymous", sourcePath: [], offset: 0)
    }
}

public enum FormulaCursorContext: Equatable, Sendable {
    case inline
    case numerator
    case denominator
    case radicalDegree
    case radicalRadicand
    case superscript
    case subscriptField
    case unknown
}

public struct FormulaCursorAnchor: Equatable, Sendable {
    public var id: String?
    public var rect: FormulaRect
    public var x: Double
    public var baseline: Double
    public var ascent: Double
    public var descent: Double
    public var context: FormulaCursorContext
    public var sourcePath: [String]
    public var fieldIdentity: String?

    public init(rect: FormulaRect, baseline: Double) {
        self.init(
            id: nil,
            rect: rect,
            x: rect.origin.x,
            baseline: baseline,
            ascent: rect.size.height + rect.origin.y - baseline,
            descent: baseline - rect.origin.y,
            context: .inline,
            sourcePath: [],
            fieldIdentity: nil
        )
    }

    public init(
        rect: FormulaRect,
        baseline: Double,
        context: FormulaCursorContext = .inline,
        sourcePath: [String] = [],
        fieldIdentity: String? = nil
    ) {
        self.init(
            id: nil,
            rect: rect,
            x: rect.origin.x,
            baseline: baseline,
            ascent: rect.size.height + rect.origin.y - baseline,
            descent: baseline - rect.origin.y,
            context: context,
            sourcePath: sourcePath,
            fieldIdentity: fieldIdentity
        )
    }

    public init(
        id: String? = nil,
        rect: FormulaRect,
        x: Double,
        baseline: Double,
        ascent: Double,
        descent: Double,
        context: FormulaCursorContext = .inline,
        sourcePath: [String] = [],
        fieldIdentity: String? = nil
    ) {
        self.id = id
        self.rect = rect
        self.x = x
        self.baseline = baseline
        self.ascent = ascent
        self.descent = descent
        self.context = context
        self.sourcePath = sourcePath
        self.fieldIdentity = fieldIdentity
    }
}

public struct FormulaPlaceholderAnchor: Equatable, Sendable {
    public var id: String
    public var rect: FormulaRect
    public var baseline: Double
    public var ascent: Double
    public var descent: Double
    public var context: FormulaCursorContext
    public var sourcePath: [String]
    public var fieldIdentity: String?
    public var kind: String
    public var widthPolicy: FormulaPlaceholderWidthPolicy

    public init(
        id: String,
        rect: FormulaRect,
        baseline: Double,
        ascent: Double,
        descent: Double,
        context: FormulaCursorContext,
        sourcePath: [String],
        fieldIdentity: String?,
        kind: String,
        widthPolicy: FormulaPlaceholderWidthPolicy
    ) {
        self.id = id
        self.rect = rect
        self.baseline = baseline
        self.ascent = ascent
        self.descent = descent
        self.context = context
        self.sourcePath = sourcePath
        self.fieldIdentity = fieldIdentity
        self.kind = kind
        self.widthPolicy = widthPolicy
    }
}
