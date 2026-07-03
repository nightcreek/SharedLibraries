import Foundation
import Combine

public final class MathInputSession: ObservableObject {
    @Published public private(set) var editorState: EditorState
    @Published public private(set) var sourceText: String
    @Published public private(set) var displayLatex: String
    @Published public private(set) var computeExpression: String

    private let inputController: InputController
    private let sourceSerializer: SourceSerializer
    private let latexRenderer: LatexMathRenderer
    private let computeSerializer: ComputeSerializer
    private var undoStack: [EditorState]
    private var redoStack: [EditorState]

    public init(editorState: EditorState = EditorState()) {
        self.editorState = editorState
        self.inputController = InputController()
        self.sourceSerializer = SourceSerializer()
        self.latexRenderer = LatexMathRenderer()
        self.computeSerializer = ComputeSerializer()
        self.undoStack = []
        self.redoStack = []
        self.sourceText = ""
        self.displayLatex = ""
        self.computeExpression = ""
        syncDerivedStrings()
    }

    public func apply(_ action: KeyboardAction) {
        let before = editorState
        let canonicalAction = InputController.canonicalAction(for: action)
        inputController.handle(action, state: &editorState)
        if shouldRecordHistory(for: canonicalAction, before: before, after: editorState) {
            recordUndoSnapshot(before)
        }
        syncDerivedStrings()
    }

    /// Returns an immutable structural snapshot for consumers outside the editor layer.
    public func formula() -> MathFormula {
        MathFormulaProjection.snapshot(from: editorState.root)
    }

    /// Returns clean LaTeX export for copy, export, compatibility, and fallback use.
    public func latexout() -> String {
        latexRenderer.renderLatex(editorState.root, editing: false)
    }

    /// Returns cursor-aware display markup derived from the immutable formula snapshot.
    public func displayout() -> FormulaDisplayMarkup {
        FormulaDisplayProjection.displayout(
            source: formula(),
            cursor: FormulaDisplayCursorState(editorCursor: editorState.cursor)
        )
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    public func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(editorState)
        editorState = previous
        syncDerivedStrings()
    }

    public func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(editorState)
        editorState = next
        syncDerivedStrings()
    }

    public func replaceEditorState(_ newState: EditorState) {
        editorState = newState
        clearHistory()
        syncDerivedStrings()
    }

    public func reset() {
        editorState = EditorState()
        clearHistory()
        syncDerivedStrings()
    }

    public func exportEditorStateJSON(prettyPrinted: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        return try encoder.encode(editorState)
    }

    public func importEditorStateJSON(_ data: Data) throws {
        let decoded = try JSONDecoder().decode(EditorState.self, from: data)
        replaceEditorState(decoded)
    }

    private func recordUndoSnapshot(_ snapshot: EditorState) {
        undoStack.append(snapshot)
        redoStack.removeAll()
    }

    private func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    private func shouldRecordHistory(
        for action: KeyboardAction,
        before: EditorState,
        after: EditorState
    ) -> Bool {
        guard before != after else { return false }

        switch action {
        case .insertCharacter,
                .insertSymbol,
                .insertOperator,
                .insertTemplate,
                .insertFunction,
                .deleteBackward,
                .deleteForward:
            return true
        case .moveLeft,
                .moveRight,
                .moveUp,
                .moveDown,
                .tab,
                .shiftTab,
                .submit,
                .cancel,
                .backspace,
                .delete,
                .enter:
            return false
        }
    }

    private func syncDerivedStrings() {
        let projection = sourceSerializer.project(editorState)
        sourceText = projection.source
        displayLatex = latexRenderer.renderLatex(editorState.root, editing: true)
        computeExpression = computeSerializer.serialize(editorState)
    }
}
