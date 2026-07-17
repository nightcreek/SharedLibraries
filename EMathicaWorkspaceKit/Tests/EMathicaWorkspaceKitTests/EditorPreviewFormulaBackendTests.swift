import EMathicaDocumentKit
import EMathicaFormulaDisplayCore
import EMathicaMathCore
import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class EditorPreviewFormulaBackendTests: XCTestCase {
    func testEditorPreviewDefaultsToSwiftMathBackend() {
        let state = makeState(markup: #"x^2"#)
        XCTAssertEqual(state.effectiveReadOnlyFormulaDisplayConfiguration.backend, .swiftMath)
    }

    func testEditorPreviewUnsupportedSwiftMathMarkupProducesDiagnosticFallbackReason() {
        let resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .editorPreview,
            rawValue: #"\mathscr{L}"#,
            fallbackText: #"\mathscr{L}"#,
            fontSize: 22,
            minHeight: 44,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let options, let fallbackReason) = resolved else {
            return XCTFail("Expected SwiftMath diagnostic formula resolution")
        }

        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(fallbackReason, .unsupportedCommand)
        XCTAssertTrue(options.cursorVisible)
    }

    func testEditorPreviewSurfaceEnablesCursorWhileReadOnlySurfacesDoNot() {
        let editorResolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .editorPreview,
            rawValue: #"x+\cursor{}+y"#,
            fallbackText: "x+y",
            fontSize: 22,
            minHeight: 44,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )
        let objectPanelResolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .objectPanel,
            rawValue: #"x+\cursor{}+y"#,
            fallbackText: "x+y",
            fontSize: 13,
            minHeight: 18,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )
        let inspectorResolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .inspector,
            rawValue: #"x+\cursor{}+y"#,
            fallbackText: "x+y",
            fontSize: 13,
            minHeight: 18,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let editorOptions, _) = editorResolved,
              case .formula(_, _, let objectPanelOptions, _) = objectPanelResolved,
              case .formula(_, _, let inspectorOptions, _) = inspectorResolved else {
            return XCTFail("Expected formula resolution for all surfaces")
        }

        XCTAssertTrue(editorOptions.cursorVisible)
        XCTAssertFalse(objectPanelOptions.cursorVisible)
        XCTAssertFalse(inspectorOptions.cursorVisible)
    }

    func testRuntimeOverrideDoesNotMutateDocumentOrInputState() throws {
        let state = makeState(markup: #"x^2"#)
        state.formulaInputState = FormulaInputState(
            editorState: .init(
                root: .sequence([.character("x")]),
                cursor: .init(path: [], offset: 1),
                selection: nil
            )
        )

        let inputBefore = state.formulaInputState
        let selectionBefore = state.selectedObjectIDs
        let undoDepthBefore = state.undoDepth

        #if DEBUG
        state.setReadOnlyFormulaBackendOverride(.swiftMath)
        #endif

        XCTAssertEqual(state.formulaInputState, inputBefore)
        XCTAssertEqual(state.selectedObjectIDs, selectionBefore)
        XCTAssertEqual(state.undoDepth, undoDepthBefore)

        let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(state.document), encoding: .utf8))
        XCTAssertFalse(encoded.contains("readOnlyFormula"))
        XCTAssertFalse(encoded.contains("swiftMath"))
    }

    private func makeState(markup: String) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: makeDocument(markup: markup),
            toolGroups: [],
            moduleProvider: EditorPreviewFormulaTestWorkspaceModuleProvider(),
            readOnlyFormulaDisplayConfiguration: .default
        )
    }

    private func makeDocument(markup: String) -> EMathicaDocument {
        EMathicaDocument(
            metadata: .init(
                title: "Editor Preview",
                moduleID: "plane",
                createdAt: .distantPast,
                updatedAt: .distantPast,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [
                MathObject(
                    name: "f",
                    type: .function,
                    expression: .init(displayText: markup, rawInput: markup, originalLatex: markup),
                    style: .init(colorToken: "blue")
                )
            ]
        )
    }
}

private struct EditorPreviewFormulaTestWorkspaceModuleProvider: WorkspaceModuleProviding {
    var module: CalculatorModuleType { .plane }
    var toolGroups: [WorkspaceToolGroup] { [] }
    var commandHandler: ModuleCommandHandler { EditorPreviewEmptyModuleCommandHandler() }

    func makeCanvasView(context: WorkspaceCanvasContext) -> AnyView {
        AnyView(EmptyView())
    }

    func makeDraftMathObject(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        previous: DraftMathObject?,
        canvasPixelSize: CGSize?,
        canvasInteracting: Bool
    ) -> DraftMathObject? {
        nil
    }

    func buildExpression(
        from source: String,
        fallbackToExplicitY: Bool
    ) -> Result<MathExpression, WorkspaceModuleBuildError> {
        .success(.init(displayText: source))
    }

    var geometryDependencyService: (any GeometryDependencyServiceProtocol)? { nil }
    var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? { nil }
    var inputCanonicalizer: any InputCanonicalizerProtocol { DefaultInputCanonicalizer() }
    var objectNamingService: (any WorkspaceObjectNamingServiceProtocol)? { nil }
}

private struct EditorPreviewEmptyModuleCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        ModuleCommandOutput()
    }
}
