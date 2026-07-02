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

    public init(editorState: EditorState = EditorState()) {
        self.editorState = editorState
        self.inputController = InputController()
        self.sourceSerializer = SourceSerializer()
        self.latexRenderer = LatexMathRenderer()
        self.computeSerializer = ComputeSerializer()
        self.sourceText = ""
        self.displayLatex = ""
        self.computeExpression = ""
        syncDerivedStrings()
    }

    public func apply(_ action: KeyboardAction) {
        inputController.handle(action, state: &editorState)
        syncDerivedStrings()
    }

    /// Returns an immutable structural snapshot for consumers outside the editor layer.
    public func formula() -> MathFormula {
        MathFormulaProjection.snapshot(from: editorState.root)
    }

    public func replaceEditorState(_ newState: EditorState) {
        editorState = newState
        syncDerivedStrings()
    }

    public func reset() {
        editorState = EditorState()
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

    private func syncDerivedStrings() {
        let projection = sourceSerializer.project(editorState)
        sourceText = projection.source
        displayLatex = latexRenderer.renderLatex(editorState.root, editing: true)
        computeExpression = computeSerializer.serialize(editorState)
    }
}
