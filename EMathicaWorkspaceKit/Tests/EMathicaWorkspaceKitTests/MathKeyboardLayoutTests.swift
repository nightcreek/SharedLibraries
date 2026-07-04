import XCTest
@testable import EMathicaWorkspaceKit

final class MathKeyboardLayoutTests: XCTestCase {
    func testKeyboardTabsExposeStableRows() {
        XCTAssertEqual(MathKeyboardTab.allCases.count, 4)

        for tab in MathKeyboardTab.allCases {
            XCTAssertFalse(tab.rows.isEmpty, "Expected \(tab.id) to expose at least one row")
            XCTAssertTrue(tab.rows.allSatisfy { !$0.isEmpty }, "Expected \(tab.id) rows to contain keys")
        }
    }

    func testEditingCommandKeysRemainAvailableAcrossKeyboardTabs() {
        XCTAssertTrue(MathKeyboardTab.numbers.rows.joined().contains(where: { $0.action == .deleteBackward }))
        XCTAssertTrue(MathKeyboardTab.functions.rows.joined().contains(where: { $0.action == .submit }))
        XCTAssertTrue(MathKeyboardTab.alphabet.rows.joined().contains(where: { $0.action == .moveLeft }))
        XCTAssertTrue(MathKeyboardTab.symbols.rows.joined().contains(where: { $0.action == .moveRight || $0.action == .submit || $0.action == .deleteBackward }))
    }

    func testWorkspaceAdapterConvertsCoreStandardLayout() {
        let rows = WorkspaceMathKeyboardAdapter.rows(for: "numbers")
        let keys = rows.joined()

        XCTAssertFalse(rows.isEmpty)
        XCTAssertTrue(keys.contains(where: { $0.title == "7" }))
        XCTAssertTrue(keys.contains(where: { $0.title == "√□" }))
        XCTAssertTrue(keys.contains(where: { $0.action == .deleteBackward }))
    }
}
