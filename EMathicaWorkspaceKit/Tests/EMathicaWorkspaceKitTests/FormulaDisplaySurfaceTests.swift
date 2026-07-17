import EMathicaFormulaDisplayCore
import EMathicaMathCore
import XCTest
@testable import EMathicaWorkspaceKit

final class FormulaDisplaySurfaceTests: XCTestCase {
    func testObjectPanelInspectorAndEditorPreviewResolveThroughSharedResolver() {
        let objectPanelResolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .objectPanel,
            rawValue: #"x^3"#,
            fallbackText: "x^3",
            fontSize: 13,
            minHeight: 18,
            allowsMultiline: false,
            configuration: .default
        )
        let inspectorResolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .inspector,
            rawValue: #"x^3"#,
            fallbackText: "x^3",
            fontSize: 13,
            minHeight: 20,
            allowsMultiline: true,
            configuration: .default
        )
        let editorPreviewResolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .editorPreview,
            rawValue: #"x^3"#,
            fallbackText: "x^3",
            fontSize: 22,
            minHeight: 44,
            allowsMultiline: false,
            configuration: .default
        )

        guard case .formula(_, _, let objectPanelOptions, _) = objectPanelResolved else {
            return XCTFail("Expected object panel formula resolution")
        }
        guard case .formula(_, _, let inspectorOptions, _) = inspectorResolved else {
            return XCTFail("Expected inspector formula resolution")
        }
        guard case .formula(_, _, let editorPreviewOptions, _) = editorPreviewResolved else {
            return XCTFail("Expected editor preview formula resolution")
        }

        XCTAssertEqual(objectPanelOptions.renderingBackend, .swiftMath)
        XCTAssertEqual(inspectorOptions.renderingBackend, .swiftMath)
        XCTAssertEqual(editorPreviewOptions.renderingBackend, .swiftMath)
    }

    func testInspectorSourceBuilderUsesInspectorSurface() {
        let object = MathObject(
            name: "f",
            type: .function,
            expression: .init(displayText: #"x^3"#, rawInput: #"x^3"#, originalLatex: #"x^3"#),
            style: .init(colorToken: "blue")
        )

        let sources = InspectorFormulaSourceBuilder.inspectorSources(for: object)

        XCTAssertFalse(sources.isEmpty)
        XCTAssertTrue(sources.allSatisfy { $0.surface == FormulaDisplaySurface.inspector })
    }
}
