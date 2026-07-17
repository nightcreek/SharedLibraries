import EMathicaDocumentKit
import EMathicaFormulaDisplayCore
import EMathicaMathCore
import EMathicaMathInputCore
import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class InspectorFormulaBackendTests: XCTestCase {
    func testInspectorDefaultsToSwiftMathBackend() {
        let state = makeState(markup: #"x^3"#)
        XCTAssertEqual(state.effectiveReadOnlyFormulaDisplayConfiguration.backend, .swiftMath)
    }

    func testInspectorUnsupportedSwiftMathMarkupProducesDiagnosticFallbackReason() {
        let resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .inspector,
            rawValue: #"\mathscr{L}"#,
            fallbackText: #"\mathscr{L}"#,
            fontSize: 13,
            minHeight: 20,
            allowsMultiline: true,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let options, let fallbackReason) = resolved else {
            return XCTFail("Expected SwiftMath diagnostic formula resolution")
        }

        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(fallbackReason, .unsupportedCommand)
    }

    func testRuntimeOverrideDoesNotEnterDocumentEncoding() throws {
        let state = makeState(markup: #"x^3"#)

        #if DEBUG
        state.setReadOnlyFormulaBackendOverride(.swiftMath)
        #endif

        let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(state.document), encoding: .utf8))
        XCTAssertFalse(encoded.contains("readOnlyFormula"))
        XCTAssertFalse(encoded.contains("swiftMath"))
    }

    private func makeState(markup: String) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: makeDocument(markup: markup),
            toolGroups: [],
            moduleProvider: InspectorFormulaTestWorkspaceModuleProvider(),
            readOnlyFormulaDisplayConfiguration: .default
        )
    }

    private func makeDocument(markup: String) -> EMathicaDocument {
        EMathicaDocument(
            metadata: .init(
                title: "Inspector",
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

private struct InspectorFormulaTestWorkspaceModuleProvider: WorkspaceModuleProviding {
    var module: CalculatorModuleType { .plane }
    var toolGroups: [WorkspaceToolGroup] { [] }
    var commandHandler: ModuleCommandHandler { InspectorFormulaEmptyModuleCommandHandler() }

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

private struct InspectorFormulaEmptyModuleCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        ModuleCommandOutput()
    }
}
