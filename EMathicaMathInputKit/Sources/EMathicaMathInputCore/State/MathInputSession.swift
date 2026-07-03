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
    private let parser: SimpleMathParser
    private var undoStack: [EditorState]
    private var redoStack: [EditorState]

    public init(editorState: EditorState = EditorState()) {
        self.editorState = editorState
        self.inputController = InputController()
        self.sourceSerializer = SourceSerializer()
        self.latexRenderer = LatexMathRenderer()
        self.computeSerializer = ComputeSerializer()
        self.parser = SimpleMathParser()
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

    /// Applies a first-version public input token by translating it into the
    /// existing editor-layer action pipeline or session-level control flow.
    public func input(_ token: MathInputToken) {
        switch token {
        case .char(let value):
            normalizedScalarSequence(from: value).forEach { apply(.insertCharacter($0)) }
        case .number(let value):
            normalizedScalarSequence(from: value).forEach { apply(.insertCharacter($0)) }
        case .op(let value):
            let normalized = MathInputCharacterNormalizer.normalize(value)
            guard !normalized.isEmpty else { return }
            apply(.insertOperator(normalized))
        case .function(let value):
            let normalized = MathInputCharacterNormalizer.normalize(value).lowercased()
            guard !normalized.isEmpty else { return }
            apply(.insertFunction(normalized))
        case .template(let value):
            apply(.insertTemplate(templateKind(for: value)))
        case .control(let value):
            handleControlToken(value)
        }
    }

    /// Imports a whole-expression LaTeX string into the editor layer. Import is
    /// parse-then-edit: the resulting editable state is still AST-backed.
    @discardableResult
    public func latexin(_ latex: String) -> Bool {
        let normalized = MathInputCharacterNormalizer.normalize(latex)
        guard let parsed = parser.parseLatex(normalized) else { return false }

        let importedRoot = normalizedImportRoot(parsed)
        let importedState = EditorState(
            root: importedRoot,
            cursor: cursorAtEnd(of: importedRoot),
            selection: nil
        )

        guard importedState != editorState else { return true }

        recordUndoSnapshot(editorState)
        editorState = importedState
        syncDerivedStrings()
        return true
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

    private func normalizedScalarSequence(from value: String) -> [String] {
        let normalized = MathInputCharacterNormalizer.normalize(value)
        return normalized.map { String($0) }
    }

    private func templateKind(for token: MathInputTemplateToken) -> TemplateKind {
        switch token {
        case .fraction:
            return .fraction
        case .sqrt:
            return .sqrt
        case .superscript:
            return .superscript
        case .subscript:
            return .subscriptTemplate
        case .parentheses:
            return .parentheses
        case .absoluteValue:
            return .absoluteValue
        }
    }

    private func handleControlToken(_ token: MathInputControlToken) {
        switch token {
        case .moveLeft:
            apply(.moveLeft)
        case .moveRight:
            apply(.moveRight)
        case .moveUp:
            apply(.moveUp)
        case .moveDown:
            apply(.moveDown)
        case .nextSlot:
            apply(.tab)
        case .previousSlot:
            apply(.shiftTab)
        case .deleteBackward:
            apply(.deleteBackward)
        case .deleteForward:
            apply(.deleteForward)
        case .submit:
            apply(.submit)
        case .cancel:
            apply(.cancel)
        case .undo:
            undo()
        case .redo:
            redo()
        }
    }

    private func normalizedImportRoot(_ parsed: MathNode) -> MathNode {
        if case .sequence = parsed {
            return parsed
        }
        return .sequence([parsed])
    }

    private func cursorAtEnd(of root: MathNode) -> EditorCursor {
        if case .sequence(let nodes) = root {
            return EditorCursor(path: [], offset: nodes.count)
        }
        return EditorCursor(path: [], offset: 0)
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
