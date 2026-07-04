import XCTest
@testable import EMathicaMathInputCore

final class MathKeyboardSemanticModelTests: XCTestCase {
    func testStandardLayoutExistsAndHasPanels() {
        let layout = MathKeyboardLayouts.standard
        XCTAssertFalse(layout.panels.isEmpty)
        XCTAssertTrue(layout.panels.allSatisfy { !$0.rows.isEmpty })
    }

    func testStandardLayoutContainsExpectedKeys() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)

        XCTAssertTrue(keys.contains(where: { $0.label == .text("7") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .text("+") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formulaMarkup(#"\frac{\placeholder{}}{\placeholder{}}"#) }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formulaMarkup(#"\sqrt{\placeholder{}}"#) }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formulaMarkup("x^{2}") || $0.label == .formulaMarkup("x^{y}") }))
        XCTAssertTrue(keys.contains(where: { $0.intent.keyboardAction == .deleteBackward }))
    }

    func testFormulaMarkupLabelsAreNonEmpty() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        let markupKeys = keys.compactMap { key -> String? in
            if case .formulaMarkup(let markup) = key.label { return markup }
            return nil
        }

        XCTAssertFalse(markupKeys.isEmpty)
        XCTAssertTrue(markupKeys.allSatisfy { !$0.isEmpty })
    }

    func testKeyIDsAreStableWithinEachPanel() {
        for panel in MathKeyboardLayouts.standard.panels {
            let ids = panel.rows.flatMap(\.keys).map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "Expected unique ids within panel \(panel.id)")
        }
    }

    func testKeyIntentsResolveToInputOrAction() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        XCTAssertTrue(keys.allSatisfy {
            switch $0.intent {
            case .input, .action:
                return true
            case .none:
                return false
            }
        })
    }
}

