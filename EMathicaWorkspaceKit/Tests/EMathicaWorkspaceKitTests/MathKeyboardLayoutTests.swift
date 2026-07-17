import XCTest
import SwiftUI
@testable import EMathicaWorkspaceKit

final class MathKeyboardLayoutTests: XCTestCase {
    func testLegacyKeyboardTabsExposeStableRows() {
        XCTAssertEqual(MathKeyboardTab.allCases.count, 4)

        for tab in MathKeyboardTab.allCases {
            if tab == .alphabet {
                XCTAssertTrue(tab.rows.isEmpty, "Expected legacy alphabet rows to be empty after runtime source extraction")
            } else {
                XCTAssertFalse(tab.rows.isEmpty, "Expected \(tab.id) to expose at least one row")
                XCTAssertTrue(tab.rows.allSatisfy { !$0.isEmpty }, "Expected \(tab.id) rows to contain keys")
            }
        }
    }

    func testLegacyEditingCommandKeysRemainAvailableAcrossKeyboardTabs() {
        XCTAssertTrue(MathKeyboardTab.numbers.rows.joined().contains(where: { $0.action == .deleteBackward }))
        XCTAssertTrue(MathKeyboardTab.functions.rows.joined().contains(where: { $0.action == .submit }))
        XCTAssertTrue(MathKeyboardTab.symbols.rows.joined().contains(where: { $0.action == .moveRight || $0.action == .submit || $0.action == .deleteBackward }))
    }

    func testLegacyWorkspaceAdapterConvertsCoreStandardLayout() {
        let rows = WorkspaceMathKeyboardAdapter.rows(for: "numbers")
        let keys = rows.joined()

        XCTAssertFalse(rows.isEmpty)
        XCTAssertTrue(keys.contains(where: { $0.title == "7" }))
        XCTAssertTrue(keys.contains(where: { $0.title == "√x" }))
        XCTAssertTrue(keys.contains(where: { $0.action == .deleteBackward }))
    }

    @MainActor
    func testLegacyMathKeyboardViewDefaultInitializerRemainsAvailable() {
        let view = MathKeyboardView { _ in }
        XCTAssertNotNil(view)
    }

    func testWorkspaceUsesMathInputKeyboardViewAsProductionKeyboardSurface() throws {
        let source = try workspaceSource(named: "WorkspaceView.swift")
        XCTAssertTrue(source.contains("MathInputKeyboardView { action in"))
        XCTAssertFalse(source.contains("MathKeyboardView {"))
    }

    func testLegacyKeyboardFilesAreIsolatedUnderLegacyFolder() {
        let root = packageRootURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources/EMathicaWorkspaceKit/Legacy/Keyboard/MathKeyboardView.swift").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources/EMathicaWorkspaceKit/Legacy/Keyboard/WorkspaceMathKeyboardAdapter.swift").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources/EMathicaWorkspaceKit/Legacy/Keyboard/KeyboardKey.swift").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources/EMathicaWorkspaceKit/Legacy/Keyboard/MathKeyboardLayout.swift").path))
    }

    private func workspaceSource(named fileName: String) throws -> String {
        try String(
            contentsOf: packageRootURL().appendingPathComponent("Sources/EMathicaWorkspaceKit/\(fileName)"),
            encoding: .utf8
        )
    }

    private func packageRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
