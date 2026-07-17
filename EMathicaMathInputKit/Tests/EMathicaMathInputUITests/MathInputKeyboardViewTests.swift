import XCTest
import SwiftUI
@testable import EMathicaMathInputUI
import EMathicaMathInputCore
import EMathicaFormulaDisplayCore
import EMathicaThemeKit

@MainActor
final class MathInputKeyboardViewTests: XCTestCase {
    func testMathInputKeyboardViewCanInitializeWithDefaultLayout() {
        let view = MathInputKeyboardView(onIntent: { (_: MathKeyboardIntent) in })
        XCTAssertNotNil(view)
    }

    func testMathInputKeyboardViewCanInitializeWithCustomStyle() {
        let style = MathKeyboardStyle.default
        let view = MathInputKeyboardView(style: style, onIntent: { (_: MathKeyboardIntent) in })
        XCTAssertNotNil(view)
    }

    func testMathInputKeyboardViewCanInitializeWithCustomLayout() {
        let layout = MathKeyboardLayout(
            panels: [
                .init(
                    id: "custom",
                    title: "自定义",
                    rows: [.init(keys: [.init(id: "x", label: .text("x"), intent: .input(.char("x")))])]
                )
            ]
        )
        let view = MathInputKeyboardView(layout: layout, onIntent: { (_: MathKeyboardIntent) in })
        XCTAssertNotNil(view)
    }

    func testDefaultLayoutContainsMultiplePanels() {
        let model = MathInputKeyboardSurfaceModel(layout: MathKeyboardLayouts.standard)
        XCTAssertGreaterThanOrEqual(model.layout.panels.count, 4)
        XCTAssertEqual(model.visiblePanel?.id, "numbers")
    }

    func testAlphabetPanelLatinLowercaseContainsTwentySixLetters() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        let labels = model.currentAlphabetKeys.compactMap { key -> String? in
            if case .formulaMarkup(let markup) = key.label { return markup }
            return nil
        }

        XCTAssertEqual(labels.count, 26)
        XCTAssertEqual(model.alphabetLetterRows.first?.keys.compactMap(formulaMarkup).map(\.self), ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"])
        XCTAssertEqual(model.alphabetLetterRows[1].keys.compactMap(formulaMarkup), ["a", "s", "d", "f", "g", "h", "j", "k", "l"])
        XCTAssertTrue(labels.contains("z"))
        XCTAssertEqual(model.alphabetLetterRows[2].keys.dropFirst().dropLast().compactMap(formulaMarkup), ["z", "x", "c", "v", "b", "n", "m"])
    }

    func testAlphabetPanelLatinUppercaseContainsTwentySixLetters() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .latin,
            letterCase: .uppercase
        )

        let labels = model.currentAlphabetKeys.compactMap { key -> String? in
            if case .formulaMarkup(let markup) = key.label { return markup }
            return nil
        }

        XCTAssertEqual(labels.count, 26)
        XCTAssertEqual(model.alphabetLetterRows.first?.keys.compactMap(formulaMarkup).map(\.self), ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
        XCTAssertEqual(model.alphabetLetterRows[1].keys.compactMap(formulaMarkup), ["A", "S", "D", "F", "G", "H", "J", "K", "L"])
        XCTAssertTrue(labels.contains("Z"))
        XCTAssertEqual(model.alphabetLetterRows[2].keys.dropFirst().dropLast().compactMap(formulaMarkup), ["Z", "X", "C", "V", "B", "N", "M"])
    }

    func testAlphabetPanelGreekLowercaseContainsExpectedCommands() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .greek,
            letterCase: .lowercase
        )

        let labels = model.currentAlphabetKeys.compactMap { key -> String? in
            if case .formulaMarkup(let markup) = key.label { return markup }
            return nil
        }

        XCTAssertEqual(labels.count, 24)
        XCTAssertTrue(labels.contains(#"\alpha"#))
        XCTAssertTrue(labels.contains(#"\theta"#))
        XCTAssertTrue(labels.contains(#"\omega"#))
        XCTAssertEqual(model.alphabetLetterRows[2].keys.last?.label, .formulaMarkup(#"a/\alpha"#))
    }

    func testAlphabetPanelGreekUppercaseContainsExpectedCommands() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .greek,
            letterCase: .uppercase
        )

        let labels = model.currentAlphabetKeys.compactMap { key -> String? in
            if case .formulaMarkup(let markup) = key.label { return markup }
            return nil
        }

        XCTAssertEqual(labels.count, 24)
        XCTAssertTrue(labels.contains(#"\Gamma"#))
        XCTAssertTrue(labels.contains(#"\Theta"#))
        XCTAssertTrue(labels.contains(#"\Omega"#))
        XCTAssertEqual(model.alphabetLetterRows[2].keys.last?.label, .formulaMarkup(#"a/\alpha"#))
    }

    func testCaseToggleChangesDisplayedLetterSet() {
        var model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        XCTAssertEqual(model.letterCase, .lowercase)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .formulaMarkup("q"))

        model.toggleLetterCase()

        XCTAssertEqual(model.letterCase, .uppercase)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .formulaMarkup("Q"))
    }

    func testScriptToggleChangesLatinAndGreekSets() {
        var model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        XCTAssertEqual(model.alphabetScript, .latin)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .formulaMarkup("q"))

        model.toggleAlphabetScript()

        XCTAssertEqual(model.alphabetScript, .greek)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .formulaMarkup(#"\alpha"#))
    }

    func testKeyLabelPresentationUsesFormulaMarkupForMathText() {
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("x")),
            .formulaMarkup("x")
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("sin")),
            .formulaMarkup(#"\sin{\placeholder{}}"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("θ")),
            .formulaMarkup(#"\theta"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("π")),
            .formulaMarkup(#"\pi"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("Ω")),
            .formulaMarkup(#"\Omega"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("×")),
            .formulaMarkup(#"\times"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .text("≤")),
            .formulaMarkup(#"\leq"#)
        )
    }

    func testKeyLabelPresentationSupportsFormulaMarkupAndSystemLabels() {
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .formulaMarkup(#"\sqrt{\placeholder{}}"#)),
            .formulaMarkup(#"\sqrt{\placeholder{}}"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .system("⌫")),
            .systemImage("delete.left")
        )
    }

    func testSystemKeysDoNotUseFormulaPath() {
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .system("←")),
            .systemImage("arrow.left")
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(for: .system("↵")),
            .systemImage("return.left")
        )
    }

    func testLabelViewCanRenderAllSupportedLabelKinds() {
        let formula = MathInputKeyboardLabelView(
            label: .formulaMarkup(#"\frac{\placeholder{}}{\placeholder{}}"#),
            style: .default,
            visualRole: .template
        )
        let text = MathInputKeyboardLabelView(
            label: .text("x"),
            style: .default,
            visualRole: .standard
        )
        let system = MathInputKeyboardLabelView(
            label: .system("↵"),
            style: .default,
            visualRole: .system
        )

        XCTAssertNotNil(formula)
        XCTAssertNotNil(text)
        XCTAssertNotNil(system)
    }

    func testIntentForwardingUsesSemanticIntent() {
        var captured: MathKeyboardIntent?
        let model = MathInputKeyboardSurfaceModel(layout: MathKeyboardLayouts.standard)
        model.forward(MathKeyboardIntent.input(MathInputToken.char("x"))) { intent in
            captured = intent
        }
        XCTAssertEqual(captured, .input(.char("x")))
    }

    func testAlphabetToggleKeysDoNotForwardWorkspaceActions() {
        var captured: MathKeyboardIntent?
        var model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        guard let scriptToggle = model.key(for: MathInputKeyboardSurfaceModel.scriptToggleKeyID) else {
            return XCTFail("Expected script toggle key")
        }
        guard let caseToggle = model.key(for: MathInputKeyboardSurfaceModel.caseToggleKeyID) else {
            return XCTFail("Expected case toggle key")
        }

        model.handle(scriptToggle) { intent in
            captured = intent
        }
        XCTAssertNil(captured)
        XCTAssertEqual(model.alphabetScript, .greek)

        model.handle(caseToggle) { intent in
            captured = intent
        }
        XCTAssertNil(captured)
        XCTAssertEqual(model.letterCase, .uppercase)
    }

    func testAlphabetToggleLabelsUseDualSemanticMarkers() {
        let latin = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .latin,
            letterCase: .lowercase
        )
        let greek = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .greek,
            letterCase: .uppercase
        )

        XCTAssertEqual(latin.key(for: MathInputKeyboardSurfaceModel.caseToggleKeyID)?.label, .formulaMarkup("Aa"))
        XCTAssertEqual(latin.key(for: MathInputKeyboardSurfaceModel.scriptToggleKeyID)?.label, .formulaMarkup(#"a/\alpha"#))
        XCTAssertEqual(greek.key(for: MathInputKeyboardSurfaceModel.caseToggleKeyID)?.label, .formulaMarkup("Aa"))
        XCTAssertEqual(greek.key(for: MathInputKeyboardSurfaceModel.scriptToggleKeyID)?.label, .formulaMarkup(#"a/\alpha"#))
    }

    func testKeyboardFormulaMetricsUseCompactKeycapSizing() {
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        XCTAssertLessThan(metrics.baseFontSize, FormulaLayoutMetrics.default.baseFontSize)
        XCTAssertGreaterThan(metrics.baseFontSize, 12)
        XCTAssertGreaterThan(metrics.placeholderHeight, 12.5)
        XCTAssertLessThan(metrics.fractionHorizontalPadding, FormulaLayoutMetrics.default.fractionHorizontalPadding)
        XCTAssertGreaterThan(metrics.delimiterHorizontalPadding, 1.8)
        XCTAssertLessThan(metrics.sqrtHorizontalPadding, FormulaLayoutMetrics.default.sqrtHorizontalPadding)
    }

    func testKeyboardFormulaMetricsKeepSqrtAndFractionReadable() {
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        let sqrtPlan = FormulaDisplayEngine(metrics: metrics).getPlan(from: .init(rawValue: #"\sqrt{\placeholder{}}"#))
        let fractionPlan = FormulaDisplayEngine(metrics: metrics).getPlan(from: .init(rawValue: #"\frac{\placeholder{}}{\placeholder{}}"#))

        XCTAssertGreaterThan(sqrtPlan.size.width, 10)
        XCTAssertGreaterThan(sqrtPlan.size.height, 10)
        XCTAssertGreaterThan(fractionPlan.size.width, 10)
        XCTAssertGreaterThan(fractionPlan.size.height, 10)
        XCTAssertFalse(sqrtPlan.placeholderRects.isEmpty)
        XCTAssertGreaterThanOrEqual(fractionPlan.placeholderRects.count, 2)
    }

    func testKeyboardFormulaMetricsKeepDelimiterAndFunctionGapsVisible() {
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        let layoutEngine = FormulaLayoutEngine(metrics: metrics)

        let parenthesesBox = layoutEngine.layout(.parentheses(content: .placeholder))
        let absoluteValueBox = layoutEngine.layout(.absoluteValue(content: .placeholder))
        let functionBox = layoutEngine.layout(.function(name: "sin", arguments: [.placeholder]))

        guard
            let parenthesesChild = parenthesesBox.children.first,
            let absoluteValueChild = absoluteValueBox.children.first
        else {
            return XCTFail("Expected delimiter children")
        }

        XCTAssertGreaterThan(parenthesesChild.origin.x, 2)
        XCTAssertGreaterThan(absoluteValueChild.origin.x, 2)
        XCTAssertLessThan(parenthesesChild.origin.x, 6)
        XCTAssertLessThan(absoluteValueChild.origin.x, 5)
        XCTAssertEqual(functionBox.children.count, 2)
        XCTAssertGreaterThan(functionBox.children[1].origin.x - functionBox.children[0].box.size.width, 0)
        XCTAssertLessThan(functionBox.children[1].origin.x - functionBox.children[0].box.size.width, 4)
    }

    func testKeyboardFormulaMetricsKeepParametricTemplateCompact() {
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        let plan = FormulaDisplayEngine(metrics: metrics).getPlan(from: .init(rawValue: #"\parametric{x}{y}{t>0}"#))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertLessThan(plan.size.width, 95)
    }

    func testActionConvenienceInitializerRemainsAvailable() {
        let view = MathInputKeyboardView { (_: KeyboardAction) in }
        XCTAssertNotNil(view)
    }

    private func formulaMarkup(_ key: MathKeyboardKey) -> String? {
        if case .formulaMarkup(let markup) = key.label {
            return markup
        }
        return nil
    }
}
