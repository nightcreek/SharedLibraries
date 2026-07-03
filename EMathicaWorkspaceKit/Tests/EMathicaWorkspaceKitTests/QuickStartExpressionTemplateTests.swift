import XCTest
import SwiftUI
import EMathicaDocumentKit
import EMathicaMathCore
@testable import EMathicaWorkspaceKit

final class QuickStartExpressionTemplateTests: XCTestCase {
    @MainActor
    func testQuickStartTemplateStartsFreshCreateSession() {
        let object = MathObject(
            name: "f_1",
            type: .function,
            expression: MathExpression(
                displayText: "y=x^2",
                sourceExpression: "y=x^2",
                computeExpression: "y=x^2"
            ),
            style: MathStyle(colorToken: "blue")
        )
        let state = makePlaneState(objects: [object])

        state.startQuickStartExpressionTemplate(.polarCurve, openKeyboard: false)

        guard let session = state.formulaEditSession else {
            XCTFail("Expected a formula edit session")
            return
        }
        XCTAssertEqual(session.mode, .createNew)
        // Quick start previews are human-readable, but the active editor source is the
        // parser/serializer round-trip form used by FormulaInputState.
        XCTAssertEqual(state.formulaInputState.source, "r=1+cos(theta)")
        XCTAssertEqual(state.inputSessionModeBadgeText, "新建")
        XCTAssertEqual(state.inputSessionPrimaryTitle, "输入函数或表达式")
        XCTAssertEqual(state.inputSessionSecondaryTitle, "支持函数、参数曲线、极坐标等二维表达式入口")
    }

    @MainActor
    func testQuickStartTemplatesHideWhileEditingExistingObject() {
        let object = MathObject(
            name: "g",
            type: .function,
            expression: MathExpression(
                displayText: "y=sin(x)",
                sourceExpression: "y=sin(x)",
                computeExpression: "y=sin(x)"
            ),
            style: MathStyle(colorToken: "green")
        )
        let state = makePlaneState(objects: [object])

        XCTAssertTrue(state.canShowQuickStartExpressionTemplates)

        state.beginEditingObjectExpression(object.id, openKeyboard: false)

        XCTAssertFalse(state.canShowQuickStartExpressionTemplates)
        XCTAssertEqual(state.inputSessionModeBadgeText, "编辑")
    }

    @MainActor
    func testPointTemplatePrefillsCoordinateSource() {
        let state = makePlaneState(objects: [])

        state.startQuickStartExpressionTemplate(.point, openKeyboard: false)

        XCTAssertEqual(state.formulaInputState.source, "A=(1,2)")
        XCTAssertEqual(state.inputSessionModeBadgeText, "新建")
        guard let intent = state.formulaInputState.semanticState.graphClassification?.intent else {
            XCTFail("Expected point quick start to produce a semantic intent")
            return
        }
        XCTAssertEqual(intent, .point(x: .integer(1), y: .integer(2)))
    }

    @MainActor
    private func makePlaneState(objects: [MathObject]) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Quick Start Template Test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: objects)
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: [],
            moduleProvider: TestWorkspaceModuleProvider()
        )
    }
}

private struct TestWorkspaceModuleProvider: WorkspaceModuleProviding {
    let module: CalculatorModuleType = .plane
    let toolGroups: [WorkspaceToolGroup] = []
    let commandHandler: ModuleCommandHandler = TestModuleCommandHandler()

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
        .success(
            MathExpression(
                displayText: source,
                sourceExpression: source,
                computeExpression: source
            )
        )
    }

    var geometryDependencyService: (any GeometryDependencyServiceProtocol)? { nil }
    var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? { nil }
    var inputCanonicalizer: any InputCanonicalizerProtocol { DefaultInputCanonicalizer() }
    var objectNamingService: (any WorkspaceObjectNamingServiceProtocol)? { DefaultWorkspaceObjectNamingService() }

    func canEditExpression(for object: MathObject) -> Bool {
        object.type == .function || object.type == .point
    }
}

private struct TestModuleCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        ModuleCommandOutput()
    }
}
