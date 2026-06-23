import EMathicaMathInputCore
import Foundation
import EMathicaMathCore

#if DEBUG
private let semanticSyncDebugLoggingEnabled = false
#endif

public extension FormulaInputState {
    public mutating func syncDerivedStrings(context: LoweringContext = .init()) {
        let sourceSerializer = SourceSerializer()
        let computeSerializer = ComputeSerializer()
        let renderer = LatexMathRenderer()
        let projection = sourceSerializer.project(editorState)
        source = projection.source
        displayLatex = renderer.renderLatex(editorState.root, editing: true)
        computeExpression = computeSerializer.serialize(editorState)
        cursorIndex = min(max(0, projection.cursorIndex), source.count)
        selectedRange = cursorIndex..<cursorIndex
        sourceCursorStops = projection.cursorStops

        let lowering = MathNodeSemanticLowering().lower(
            editorState.root,
            context: context
        )
        let parameterSymbolNames = Set(
            context.symbolTable.symbols.values
                .filter { $0.role == .parameter }
                .map(\.name)
        )
        if let expr = lowering.expr {
            semanticState = FormulaSemanticState(
                expression: expr,
                diagnostics: lowering.diagnostics,
                graphClassification: GraphClassifier(parameterSymbolNames: parameterSymbolNames).classify(expr)
            )
        } else {
            semanticState = FormulaSemanticState(
                expression: nil,
                diagnostics: lowering.diagnostics,
                graphClassification: nil
            )
        }

        #if DEBUG
        if semanticSyncDebugLoggingEnabled {
            print("[SemanticSync] \(semanticState.debugSummary)")
        }
        #endif
    }
}
