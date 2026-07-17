import EMathicaFormulaDisplayCore
import EMathicaMathInputCore
import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class FormulaDisplayPreviewViewTests: XCTestCase {
    func testEditorPreviewUsesSingleMinimumLayoutHeightFloor() {
        XCTAssertEqual(FormulaEditingDisplayView.minimumLayoutHeight, 44 as CGFloat)
        XCTAssertEqual(
            FormulaReadOnlyDisplayResolver.makeMetrics(
                surface: .editorPreview,
                fontSize: 22,
                minHeight: FormulaEditingDisplayView.minimumLayoutHeight
            ).minimumBoxSize.height,
            44
        )
    }

    func testFormulaDisplayPreviewViewCanInitializeFromRawValue() {
        let view = FormulaDisplayPreviewView(rawValue: "x+1")
        XCTAssertNotNil(view)
    }

    func testFormulaDisplayPreviewViewCanInitializeFromInputState() {
        let state = FormulaInputState()
        let view = FormulaDisplayPreviewView(inputState: state)
        XCTAssertNotNil(view)
    }

    func testPreviewBridgeUsesDisplayMarkupRawValueWithoutChangingSource() {
        var state = FormulaInputState()
        state.source = "x+1"
        let sourceBefore = state.source
        let displayLatexBefore = state.displayLatex
        let expectedDocument = state.displayDocumentSnapshot

        let view = FormulaDisplayPreviewView(inputState: state)

        XCTAssertNotNil(view)
        XCTAssertEqual(state.displayDocumentSnapshot, expectedDocument)
        XCTAssertEqual(state.source, sourceBefore)
        XCTAssertEqual(state.displayLatex, displayLatexBefore)
    }

    func testPreviewBridgePreservesDisplayLatexFallback() {
        let state = FormulaInputState(
            source: "x+1",
            displayLatex: "x+1"
        )

        let view = FormulaDisplayPreviewView(inputState: state)

        XCTAssertNotNil(view)
        XCTAssertEqual(state.displayLatex, "x+1")
        XCTAssertEqual(state.source, "x+1")
    }

    func testPreviewBridgeUsesCleanLatexFallbackWithoutInternalCursorToken() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character("(")]),
                cursor: EditorCursor(path: [], offset: 1),
                selection: nil
            )
        )

        XCTAssertFalse(state.latexOutputSnapshot.contains(#"\cursor"#))
        XCTAssertTrue(state.displayDocumentSnapshot == MathInputProjectionAdapter.displayDocument(from: state))
    }

    func testPreviewBridgeProjectionSnapshotPreservesInsertionCursorMap() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([
                    .template(
                        .init(
                            kind: .sqrt,
                            fields: [
                                TemplateField(
                                    id: .radicand,
                                    node: .sequence([])
                                )
                            ]
                        )
                    )
                ]),
                cursor: EditorCursor(
                    path: [.sequenceIndex(0), .templateField(.radicand)],
                    offset: 1
                ),
                selection: nil
            )
        )

        let snapshot = state.displayProjectionSnapshot(includesInsertionMarkers: true)

        XCTAssertEqual(
            snapshot.cursor(
                for: FormulaInsertionID(
                    sourcePath: ["sequence[0]", "field.radicand"],
                    offset: 1,
                    affinity: FormulaInsertionAffinity.trailing
                )
            ),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.radicand)],
                offset: 1
            )
        )
    }

    func testWorkspaceKitCanImportFormulaDisplaySwiftUIThroughPreviewBridge() {
        let view = FormulaDisplayPreviewView(rawValue: #"\frac{x}{\placeholder{}}"#)
        XCTAssertNotNil(view)
    }

    func testPreviewBridgeDoesNotRenderSwiftMathErrorsAsUserVisibleText() throws {
        let previewSource = try workspaceSource(at: "Input/FormulaDisplayPreviewView.swift")
        let snapshotSource = try formulaDisplaySwiftUISource(named: "FormulaSwiftMathSnapshotView.swift")

        XCTAssertTrue(previewSource.contains("FormulaDisplayView("))
        XCTAssertFalse(previewSource.contains("Text(error"))
        XCTAssertFalse(previewSource.contains("localizedDescription"))
        XCTAssertFalse(snapshotSource.contains("Text(error.message)"))
    }

    func testPreviewBridgeFallbackTextStillUsesFormulaDisplayPath() {
        let view = FormulaDisplayPreviewView(rawValue: "", fallbackText: #"\sqrt{\placeholder{}}"#)
        XCTAssertNotNil(view)
    }

    func testFormulaEditingDisplayViewCanInitializeWithoutChangingInteractionModel() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character("x"), .operatorSymbol("\\leq"), .character("2")]),
                cursor: EditorCursor(path: [], offset: 3),
                selection: nil
            )
        )

        let view = FormulaEditingDisplayView(
            inputState: state,
            isFocused: true,
            onTapCursor: { _ in },
            onKeyboardAction: { _ in }
        )

        XCTAssertNotNil(view)
    }

    func testWorkspaceViewNoLongerUsesLegacyPreferredHeightForEditorPreviewSizing() throws {
        let source = try workspaceSource(named: "WorkspaceView.swift")
        XCTAssertFalse(source.contains(".frame(minHeight: FormulaEditorView.preferredHeight"))
        XCTAssertFalse(source.contains(".fixedSize(horizontal: false, vertical: true)"))
        XCTAssertTrue(source.contains("FormulaEditingDisplayView.minimumLayoutHeight"))
    }

    func testEditingDisplayBridgeRendersLeqAsVisibleFormulaSymbol() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character("x"), .operatorSymbol("\\leq"), .character("2")]),
                cursor: EditorCursor(path: [], offset: 3),
                selection: nil
            )
        )

        let rawValue = state.displayMarkupSnapshot.rawValue
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: rawValue))

        XCTAssertTrue(rawValue.contains(#"\leq"#))
        XCTAssertTrue(
            plan.elements.contains {
                if case .text(let element) = $0 {
                    return element.text == "≤"
                }
                return false
            }
        )
        XCTAssertFalse(
            plan.elements.contains {
                if case .text(let element) = $0 {
                    return element.text.contains(#"\leq"#)
                }
                return false
            }
        )
    }

    func testMathInputDisplayoutFeedsFormulaDisplayEngine() {
        let session = MathInputSession()
        session.input(.template(.fraction))
        session.input(.char("x"))
        session.input(.control(.nextSlot))

        let state = FormulaInputState(editorState: session.editorState)

        let rawValue = state.displayMarkupSnapshot.rawValue
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: rawValue))

        XCTAssertTrue(rawValue.contains(#"\frac"#))
        XCTAssertTrue(rawValue.contains(#"\cursor{}"#))
        XCTAssertTrue(rawValue.contains(#"\placeholder{}"#))
        XCTAssertFalse(plan.elements.isEmpty)
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertFalse(plan.cursorRects.isEmpty)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
    }

    func testRawLatexFallbackRemainsVisibleAcrossDisplayBridge() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character(".")]),
                cursor: EditorCursor(path: [], offset: 1),
                selection: nil
            )
        )

        let rawValue = state.displayMarkupSnapshot.rawValue
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: rawValue))

        XCTAssertFalse(rawValue.isEmpty)
        XCTAssertFalse(plan.elements.isEmpty)
        XCTAssertTrue(
            plan.elements.contains { element in
                if case .text(let text) = element {
                    return !text.text.isEmpty
                }
                return false
            }
        )
    }

    func testInputDockPreviewSurfaceHidesHeaderTextAndSuggestionChromeByDefault() {
        XCTAssertFalse(WorkspaceInlineInputVisualMetrics.showsParameterSuggestionsInDock)
        XCTAssertFalse(WorkspaceInlineInputVisualMetrics.showsCommitErrorBanner)
        XCTAssertFalse(WorkspaceInlineInputVisualMetrics.showsPiecewiseAppendRowControl)
    }

    private func workspaceSource(named fileName: String) throws -> String {
        let sourceDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/EMathicaWorkspaceKit")
        return try String(contentsOf: sourceDirectory.appendingPathComponent(fileName), encoding: .utf8)
    }

    private func workspaceSource(at relativePath: String) throws -> String {
        let sourceDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/EMathicaWorkspaceKit")
        return try String(contentsOf: sourceDirectory.appendingPathComponent(relativePath), encoding: .utf8)
    }

    private func formulaDisplaySwiftUISource(named fileName: String) throws -> String {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("EMathicaFormulaDisplayKit")
        return try String(
            contentsOf: packageRoot
                .appendingPathComponent("Sources/EMathicaFormulaDisplaySwiftUI")
                .appendingPathComponent(fileName),
            encoding: .utf8
        )
    }
}
