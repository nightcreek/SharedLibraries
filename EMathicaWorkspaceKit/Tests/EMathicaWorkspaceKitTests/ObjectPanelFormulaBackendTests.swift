import EMathicaDocumentKit
import EMathicaFormulaDisplayCore
import EMathicaMathCore
import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class ObjectPanelFormulaBackendTests: XCTestCase {
    func testDefaultObjectPanelConfigurationPrefersSwiftMathStandard() {
        XCTAssertEqual(ObjectPanelFormulaDisplayConfiguration.default.backend, .swiftMath)
        XCTAssertEqual(ObjectPanelFormulaDisplayConfiguration.default.fontRole, .standard)
    }

    func testExplicitSwiftMathConfigurationIsPreserved() {
        let configuration = ObjectPanelFormulaDisplayConfiguration(
            backend: .swiftMath,
            fontRole: .standard
        )

        let resolved = ObjectPanelFormulaDisplayResolver.resolveUncached(
            rawValue: #"\frac{x}{2}"#,
            fallbackText: "x/2",
            fontSize: 13,
            minHeight: 24,
            allowsMultiline: false,
            configuration: configuration
        )

        guard case .formula(_, _, let options, let fallbackReason) = resolved else {
            return XCTFail("Expected formula mode")
        }
        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(options.fontRole, .standard)
        XCTAssertNil(fallbackReason)
    }

    func testInvalidSwiftMathInputStaysOnSwiftMathPathWithDiagnosticReason() {
        let resolved = ObjectPanelFormulaDisplayResolver.resolveUncached(
            rawValue: #"\mathscr{L}"#,
            fallbackText: "L",
            fontSize: 13,
            minHeight: 24,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let options, let fallbackReason) = resolved else {
            return XCTFail("Expected SwiftMath diagnostic formula resolution")
        }
        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(fallbackReason, .unsupportedCommand)
    }

    func testEmptyFormulaFallsBackToPlainText() {
        let resolved = ObjectPanelFormulaDisplayResolver.resolveUncached(
            rawValue: "",
            fallbackText: "",
            fontSize: 13,
            minHeight: 24,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .plainText(let text, let reason) = resolved else {
            return XCTFail("Expected plain text fallback")
        }
        XCTAssertEqual(text, "")
        XCTAssertEqual(reason, .emptyOutput)
    }

    func testBackendSelectionDoesNotEnterDocumentModel() throws {
        let document = EMathicaDocument(
            metadata: .init(
                title: "AB",
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
                    expression: .init(displayText: "y=x^2"),
                    style: .init(colorToken: "blue")
                )
            ]
        )
        let configuration = WorkspaceConfiguration(
            module: .plane,
            moduleProvider: TestWorkspaceModuleProvider(),
            toolGroups: [],
            objectPanelFormulaDisplay: .init(backend: .swiftMath, fontRole: .standard)
        )

        let encodedDocument = try String(data: JSONEncoder().encode(document), encoding: .utf8)

        XCTAssertNotNil(encodedDocument)
        XCTAssertFalse(encodedDocument?.contains("swiftMath") ?? true)
        XCTAssertEqual(configuration.objectPanelFormulaDisplay.backend, .swiftMath)
    }
}

private struct TestWorkspaceModuleProvider: WorkspaceModuleProviding {
    var module: CalculatorModuleType { .plane }
    var toolGroups: [WorkspaceToolGroup] { [] }
    var commandHandler: ModuleCommandHandler { EmptyModuleCommandHandler() }

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

private struct EmptyModuleCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        ModuleCommandOutput()
    }
}
