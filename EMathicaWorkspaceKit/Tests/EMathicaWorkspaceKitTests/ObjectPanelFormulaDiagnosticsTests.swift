import EMathicaDocumentKit
import EMathicaMathCore
import EMathicaMathInputCore
import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class ObjectPanelFormulaDiagnosticsTests: XCTestCase {
    func testSwiftMathSuccessDoesNotIncreaseFallbackCount() {
        let state = makeState(markup: #"\frac{1}{2}"#)

        #if DEBUG
        state.setObjectPanelFormulaBackendOverride(.swiftMath)
        XCTAssertGreaterThanOrEqual(state.objectPanelFormulaDiagnostics.swiftMathAttemptCount, 1)
        XCTAssertEqual(state.objectPanelFormulaDiagnostics.fallbackCount, 0)
        XCTAssertNil(state.objectPanelFormulaDiagnostics.lastFallbackReason)
        #endif
    }

    func testSwiftMathFailureIncreasesFallbackCountAndStoresReason() {
        let state = makeState(markup: #"\mathscr{L}"#)

        #if DEBUG
        state.setObjectPanelFormulaBackendOverride(.swiftMath)
        XCTAssertGreaterThanOrEqual(state.objectPanelFormulaDiagnostics.swiftMathAttemptCount, 1)
        XCTAssertGreaterThanOrEqual(state.objectPanelFormulaDiagnostics.swiftMathFallbackCount, 1)
        XCTAssertGreaterThanOrEqual(state.objectPanelFormulaDiagnostics.fallbackCount, 1)
        XCTAssertEqual(state.objectPanelFormulaDiagnostics.lastFallbackReason, .unsupportedCommand)
        #endif
    }

    func testParserFailureStoresParserReason() {
        let state = makeState(markup: #"\frac{1}{"#)

        #if DEBUG
        state.setObjectPanelFormulaBackendOverride(.swiftMath)
        XCTAssertGreaterThanOrEqual(state.objectPanelFormulaDiagnostics.swiftMathFallbackCount, 1)
        XCTAssertEqual(state.objectPanelFormulaDiagnostics.lastFallbackReason, .parserError)
        #endif
    }

    func testDiagnosticsDoNotEnterDocumentEncoding() throws {
        let document = makeDocument(markup: #"\mathscr{L}"#)
        let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(document), encoding: .utf8))

        XCTAssertFalse(encoded.contains("swiftMathFallbackCount"))
        XCTAssertFalse(encoded.contains("lastFallbackReason"))
        XCTAssertFalse(encoded.contains("objectPanelFormula"))
    }

    private func makeState(markup: String) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: makeDocument(markup: markup),
            toolGroups: [],
            moduleProvider: DiagnosticsTestWorkspaceModuleProvider(),
            objectPanelFormulaDisplayConfiguration: .default
        )
    }

    private func makeDocument(markup: String) -> EMathicaDocument {
        EMathicaDocument(
            metadata: .init(
                title: "Diagnostics",
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

private struct DiagnosticsTestWorkspaceModuleProvider: WorkspaceModuleProviding {
    var module: CalculatorModuleType { .plane }
    var toolGroups: [WorkspaceToolGroup] { [] }
    var commandHandler: ModuleCommandHandler { DiagnosticsEmptyModuleCommandHandler() }

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

private struct DiagnosticsEmptyModuleCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        ModuleCommandOutput()
    }
}
