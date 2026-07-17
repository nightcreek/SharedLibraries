import XCTest
@testable import EMathicaMathInputCore

final class MathKeyboardSemanticModelTests: XCTestCase {
    func testStandardLayoutExistsAndHasPanels() {
        let layout = MathKeyboardLayouts.standard
        XCTAssertFalse(layout.panels.isEmpty)
        XCTAssertTrue(
            layout.panels.allSatisfy { panel in
                panel.id == "alphabet" || !panel.rows.isEmpty
            }
        )
        XCTAssertEqual(layout.panels.first(where: { $0.id == "alphabet" })?.rows ?? [], [])
    }

    func testStandardLayoutContainsExpectedKeys() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)

        XCTAssertTrue(keys.contains(where: { $0.label == .symbol(markup: "7", fallback: "7") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .symbol(markup: "+", fallback: "+") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .symbol(markup: #"\div"#, fallback: "÷") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formula(markup: #"\sqrt{x}"#, fallback: "√x") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formula(markup: "x^{2}", fallback: "x^2") || $0.label == .formula(markup: "x^{n}", fallback: "x^n") }))
        XCTAssertTrue(keys.contains(where: { $0.intent.keyboardAction == .deleteBackward }))
        XCTAssertTrue(keys.contains(where: { $0.id == "numbers-div" && $0.intent.keyboardAction == .insertTemplate(.fraction) }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formula(markup: #"\begin{cases}x=x(t)\\y=y(t)\end{cases}"#, fallback: "x(t), y(t)") }))
        XCTAssertTrue(keys.contains(where: { $0.label == .formula(markup: #"\begin{cases}f\left(x\right)&\\\ldots&\end{cases}"#, fallback: "cases") }))
    }

    func testMathVisibleCharactersUseSwiftMathBackedLabels() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        let ids = ["numbers-x", "numbers-7", "numbers-dot", "symbols-open-brace", "symbols-comma", "symbols-empty"]

        for id in ids {
            guard let key = keys.first(where: { $0.id == id }) else {
                return XCTFail("Missing key \(id)")
            }
            XCTAssertNotNil(key.label.staticMarkup, "Expected SwiftMath-backed markup for \(id)")
        }
    }

    func testDivisionKeysUseDivLabelWhileKeepingFractionIntent() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)

        for id in ["numbers-div", "symbols-div"] {
            guard let key = keys.first(where: { $0.id == id }) else {
                return XCTFail("Missing key \(id)")
            }
            XCTAssertEqual(key.label, .symbol(markup: #"\div"#, fallback: "÷"))
            XCTAssertEqual(key.intent.keyboardAction, .insertTemplate(.fraction))
        }
    }

    func testKeyboardMultiplicationKeysShowTimesWhileFormulaDisplayUsesCdotElsewhere() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)

        for id in ["numbers-mul", "symbols-mul"] {
            guard let key = keys.first(where: { $0.id == id }) else {
                return XCTFail("Missing key \(id)")
            }
            XCTAssertEqual(key.label, .symbol(markup: #"\times"#, fallback: "×"))
            XCTAssertEqual(key.intent, .input(.op("*")))
        }
    }

    func testFunctionsPanelContainsOnlyFunctionAndTemplateContentKeys() {
        guard let functionsPanel = MathKeyboardLayouts.standard.panels.first(where: { $0.id == "functions" }) else {
            return XCTFail("Missing functions panel")
        }

        let keyIDs = Set(functionsPanel.rows.flatMap(\.keys).map(\.id))
        XCTAssertFalse(keyIDs.contains("functions-open-paren"))
        XCTAssertFalse(keyIDs.contains("functions-close-paren"))
        XCTAssertFalse(keyIDs.contains("functions-x"))
        XCTAssertFalse(keyIDs.contains("functions-y"))
        XCTAssertFalse(keyIDs.contains("functions-t"))
        XCTAssertFalse(keyIDs.contains("functions-e"))
        XCTAssertFalse(keyIDs.contains("functions-plus"))
        XCTAssertFalse(keyIDs.contains("functions-minus"))
    }

    func testSymbolsPanelNoLongerContainsGreekLetterKeys() {
        guard let symbolsPanel = MathKeyboardLayouts.standard.panels.first(where: { $0.id == "symbols" }) else {
            return XCTFail("Missing symbols panel")
        }

        let keyIDs = Set(symbolsPanel.rows.flatMap(\.keys).map(\.id))
        XCTAssertFalse(keyIDs.contains("symbols-alpha"))
        XCTAssertFalse(keyIDs.contains("symbols-beta"))
        XCTAssertFalse(keyIDs.contains("symbols-theta"))
        XCTAssertTrue(keyIDs.contains("symbols-empty"))
        XCTAssertTrue(keyIDs.contains("symbols-cdot"))
    }

    func testStaticFormulaMarkupLabelsAreNonEmpty() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        let markupKeys = keys.compactMap(\.label.staticMarkup)

        XCTAssertFalse(markupKeys.isEmpty)
        XCTAssertTrue(markupKeys.allSatisfy { !$0.isEmpty })
    }

    func testKeyboardLabelsDoNotContainEditingControlMarkup() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        XCTAssertTrue(keys.allSatisfy { !$0.label.containsEditingControlMarkup })
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
