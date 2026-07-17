import EMathicaDocumentKit
import EMathicaFormulaDisplayCore
import EMathicaMathCore
import EMathicaMathInputCore
import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class ObjectPanelFormulaRuntimeToggleTests: XCTestCase {
    func testInitialEffectiveBackendComesFromWorkspaceConfiguration() {
        let state = makeState(
            configuration: .init(backend: .legacy, fontRole: .standard),
            objects: [makeFunction(name: "f", markup: #"\frac{x+1}{x-1}"#)]
        )

        XCTAssertEqual(state.effectiveObjectPanelFormulaDisplayConfiguration.backend, .legacy)
        #if DEBUG
        XCTAssertNil(state.objectPanelFormulaDisplayRuntimeOverride)
        #endif
    }

    func testDebugOverrideCanSwitchBackendWithoutTouchingDocumentSelectionOrUndo() {
        let object = makeFunction(name: "g", markup: #"\sqrt{x^2+1}"#)
        let state = makeState(
            configuration: .init(backend: .legacy, fontRole: .standard),
            objects: [object]
        )

        let beforeDocument = state.document
        let beforeSelection = state.selectedObjectIDs
        let beforeUndoDepth = state.undoDepth
        let beforeRedoDepth = state.redoDepth

        #if DEBUG
        state.setObjectPanelFormulaBackendOverride(.swiftMath)
        XCTAssertEqual(state.objectPanelFormulaDisplayRuntimeOverride?.backend, .swiftMath)
        #endif

        XCTAssertEqual(state.effectiveObjectPanelFormulaDisplayConfiguration.backend, .swiftMath)
        XCTAssertEqual(state.document, beforeDocument)
        XCTAssertEqual(state.selectedObjectIDs, beforeSelection)
        XCTAssertEqual(state.undoDepth, beforeUndoDepth)
        XCTAssertEqual(state.redoDepth, beforeRedoDepth)
    }

    func testClearingOverrideRestoresConfigurationBackend() {
        let state = makeState(
            configuration: .init(backend: .legacy, fontRole: .standard),
            objects: [makeFunction(name: "h", markup: "x_i^2")]
        )

        #if DEBUG
        state.setObjectPanelFormulaBackendOverride(.swiftMath)
        XCTAssertEqual(state.effectiveObjectPanelFormulaDisplayConfiguration.backend, .swiftMath)

        state.clearObjectPanelFormulaBackendOverride()
        XCTAssertNil(state.objectPanelFormulaDisplayRuntimeOverride)
        #endif

        XCTAssertEqual(state.effectiveObjectPanelFormulaDisplayConfiguration.backend, .legacy)
    }

    private func makeState(
        configuration: ObjectPanelFormulaDisplayConfiguration,
        objects: [MathObject]
    ) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: makeDocument(objects: objects),
            toolGroups: [],
            moduleProvider: RuntimeToggleTestWorkspaceModuleProvider(),
            objectPanelFormulaDisplayConfiguration: configuration
        )
    }

    private func makeDocument(objects: [MathObject]) -> EMathicaDocument {
        EMathicaDocument(
            metadata: .init(
                title: "Runtime Toggle",
                moduleID: "plane",
                createdAt: .distantPast,
                updatedAt: .distantPast,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: objects
        )
    }

    private func makeFunction(name: String, markup: String) -> MathObject {
        MathObject(
            name: name,
            type: .function,
            expression: .init(
                displayText: markup,
                rawInput: markup,
                originalLatex: markup
            ),
            style: .init(colorToken: "blue")
        )
    }
}

private struct RuntimeToggleTestWorkspaceModuleProvider: WorkspaceModuleProviding {
    var module: CalculatorModuleType { .plane }
    var toolGroups: [WorkspaceToolGroup] { [] }
    var commandHandler: ModuleCommandHandler { RuntimeToggleEmptyModuleCommandHandler() }

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

private struct RuntimeToggleEmptyModuleCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        ModuleCommandOutput()
    }
}
