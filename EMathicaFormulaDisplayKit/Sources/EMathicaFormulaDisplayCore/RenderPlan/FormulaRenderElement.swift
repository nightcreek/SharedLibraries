import Foundation

public enum FormulaRenderFontRole: Equatable, Sendable {
    case normal
    case script
    case operatorSymbol
    case function
    case raw
    case error
}

public enum FormulaRenderStrokeRole: Equatable, Sendable {
    case fractionLine
    case radical
    case cursor
    case delimiter
    case debug
}

public enum FormulaRenderFillRole: Equatable, Sendable {
    case placeholder
    case debug
}

public struct FormulaTextElement: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var text: String
    public var fontRole: FormulaRenderFontRole
    public var frame: FormulaRect

    public init(
        id: FormulaLayoutID,
        text: String,
        fontRole: FormulaRenderFontRole,
        frame: FormulaRect
    ) {
        self.id = id
        self.text = text
        self.fontRole = fontRole
        self.frame = frame
    }
}

public struct FormulaLineElement: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var frame: FormulaRect
    public var role: FormulaRenderStrokeRole

    public init(
        id: FormulaLayoutID,
        frame: FormulaRect,
        role: FormulaRenderStrokeRole
    ) {
        self.id = id
        self.frame = frame
        self.role = role
    }
}

public struct FormulaRadicalElement: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var frame: FormulaRect
    public var overlineStart: FormulaPoint
    public var overlineEnd: FormulaPoint
    public var role: FormulaRenderStrokeRole

    public init(
        id: FormulaLayoutID,
        frame: FormulaRect,
        overlineStart: FormulaPoint,
        overlineEnd: FormulaPoint,
        role: FormulaRenderStrokeRole
    ) {
        self.id = id
        self.frame = frame
        self.overlineStart = overlineStart
        self.overlineEnd = overlineEnd
        self.role = role
    }
}

public struct FormulaCursorElement: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var frame: FormulaRect
    public var role: FormulaRenderStrokeRole

    public init(
        id: FormulaLayoutID,
        frame: FormulaRect,
        role: FormulaRenderStrokeRole = .cursor
    ) {
        self.id = id
        self.frame = frame
        self.role = role
    }
}

public struct FormulaPlaceholderElement: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var frame: FormulaRect
    public var fillRole: FormulaRenderFillRole

    public init(
        id: FormulaLayoutID,
        frame: FormulaRect,
        fillRole: FormulaRenderFillRole = .placeholder
    ) {
        self.id = id
        self.frame = frame
        self.fillRole = fillRole
    }
}

public struct FormulaDebugFrameElement: Equatable, Sendable {
    public var id: FormulaLayoutID
    public var frame: FormulaRect
    public var strokeRole: FormulaRenderStrokeRole

    public init(
        id: FormulaLayoutID,
        frame: FormulaRect,
        strokeRole: FormulaRenderStrokeRole = .debug
    ) {
        self.id = id
        self.frame = frame
        self.strokeRole = strokeRole
    }
}

public enum FormulaRenderElement: Equatable, Sendable {
    case text(FormulaTextElement)
    case line(FormulaLineElement)
    case radical(FormulaRadicalElement)
    case cursor(FormulaCursorElement)
    case placeholder(FormulaPlaceholderElement)
    case debugFrame(FormulaDebugFrameElement)
}
