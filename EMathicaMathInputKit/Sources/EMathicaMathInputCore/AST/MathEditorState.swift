import Foundation

public struct EditorState: Hashable, Codable {
    public var root: MathNode
    public var cursor: EditorCursor
    public var selection: EditorSelection?

    public init(
        root: MathNode = .sequence([]),
        cursor: EditorCursor = EditorCursor(path: [], offset: 0),
        selection: EditorSelection? = nil
    ) {
        self.root = root
        self.cursor = cursor
        self.selection = selection
    }
}

public struct EditorCursor: Hashable, Codable {
    public init(path: [EditorPathComponent] = [], offset: Int = 0) { self.path = path; self.offset = offset }
    public var path: [EditorPathComponent]
    public var offset: Int
}

public struct EditorSelection: Hashable, Codable {
    public var anchor: EditorCursor
    public var focus: EditorCursor
}

public enum EditorPathComponent: Hashable, Codable {
    case sequenceIndex(Int)
    case templateField(FieldID)
}

public enum KeyboardAction: Hashable {
    case insertCharacter(String)
    case insertSymbol(String)
    case insertOperator(String)
    case insertTemplate(TemplateKind)
    case insertFunction(String)
    case moveLeft
    case moveRight
    case moveUp
    case moveDown
    case tab
    case shiftTab
    case deleteBackward
    case deleteForward
    case submit
    case cancel
    // Legacy aliases (kept for compatibility; canonicalized in InputController)
    case backspace
    case delete
    case enter
}
