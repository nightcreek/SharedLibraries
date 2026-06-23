import EMathicaMathInputCore
import EMathicaMathCore
import Foundation

public struct FormulaInputState: Equatable {
    public var editorState: EditorState
    public var semanticState: FormulaSemanticState
    public var source: String
    public var displayLatex: String
    public var computeExpression: String
    public var cursorIndex: Int
    public var currentPlaceholderIndex: Int?
    public var selectedRange: Range<Int>?
    public var sourceCursorStops: [CursorStop]
    public var isEditing: Bool

    public init(
        editorState: EditorState = EditorState(),
        semanticState: FormulaSemanticState = .empty,
        source: String = "",
        displayLatex: String = "",
        computeExpression: String = "",
        cursorIndex: Int = 0,
        currentPlaceholderIndex: Int? = nil,
        selectedRange: Range<Int>? = nil,
        sourceCursorStops: [CursorStop] = [],
        isEditing: Bool = false
    ) {
        self.editorState = editorState
        self.semanticState = semanticState
        self.source = source
        self.displayLatex = displayLatex
        self.computeExpression = computeExpression
        self.cursorIndex = cursorIndex
        self.currentPlaceholderIndex = currentPlaceholderIndex
        self.selectedRange = selectedRange
        self.sourceCursorStops = sourceCursorStops
        self.isEditing = isEditing
    }
}

