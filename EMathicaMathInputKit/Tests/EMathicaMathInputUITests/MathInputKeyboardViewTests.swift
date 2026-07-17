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

    func testAlphabetPanelUsesRuntimeSurfaceRowsAsAuthoritativeSource() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        let staticAlphabetRows = MathKeyboardLayouts.standard.panels.first(where: { $0.id == "alphabet" })?.rows ?? []

        XCTAssertTrue(staticAlphabetRows.isEmpty)
        XCTAssertEqual(model.visiblePanel?.rows, model.alphabetRows)
        XCTAssertFalse(model.alphabetRows.isEmpty)
    }

    func testAlphabetPanelLatinLowercaseContainsTwentySixLetters() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        let labels = model.currentAlphabetKeys.compactMap(formulaMarkup)

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

        let labels = model.currentAlphabetKeys.compactMap(formulaMarkup)

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
            if case .symbol(let markup, _) = key.label { return markup }
            return nil
        }

        XCTAssertEqual(labels.count, 24)
        XCTAssertTrue(labels.contains(#"\alpha"#))
        XCTAssertTrue(labels.contains(#"\theta"#))
        XCTAssertTrue(labels.contains(#"\omega"#))
        XCTAssertEqual(model.alphabetLetterRows[2].keys.last?.label, .formula(markup: #"a/\alpha"#, fallback: "a/α"))
    }

    func testAlphabetPanelGreekUppercaseUsesCanonicalCommandsAndSharedGlyphFallbacks() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .greek,
            letterCase: .uppercase
        )

        let labels = model.currentAlphabetKeys.compactMap { key -> String? in
            if case .symbol(let markup, _) = key.label { return markup }
            return nil
        }

        XCTAssertEqual(labels.count, 24)
        XCTAssertTrue(labels.contains(#"\Gamma"#))
        XCTAssertTrue(labels.contains(#"\Delta"#))
        XCTAssertTrue(labels.contains(#"\Theta"#))
        XCTAssertTrue(labels.contains(#"\Lambda"#))
        XCTAssertTrue(labels.contains(#"\Xi"#))
        XCTAssertTrue(labels.contains(#"\Pi"#))
        XCTAssertTrue(labels.contains(#"\Sigma"#))
        XCTAssertTrue(labels.contains(#"\Phi"#))
        XCTAssertTrue(labels.contains(#"\Psi"#))
        XCTAssertTrue(labels.contains(#"\Omega"#))
        XCTAssertFalse(labels.contains(#"\Alpha"#))
        XCTAssertFalse(labels.contains(#"\Beta"#))
        XCTAssertFalse(labels.contains(#"\Epsilon"#))
        XCTAssertFalse(labels.contains(#"\Zeta"#))
        XCTAssertFalse(labels.contains(#"\Eta"#))
        XCTAssertFalse(labels.contains(#"\Iota"#))
        XCTAssertFalse(labels.contains(#"\Kappa"#))
        XCTAssertFalse(labels.contains(#"\Mu"#))
        XCTAssertFalse(labels.contains(#"\Nu"#))
        XCTAssertFalse(labels.contains(#"\Omicron"#))
        XCTAssertFalse(labels.contains(#"\Rho"#))
        XCTAssertFalse(labels.contains(#"\Tau"#))
        XCTAssertFalse(labels.contains(#"\Upsilon"#))
        XCTAssertFalse(labels.contains(#"\Chi"#))
        XCTAssertTrue(labels.contains("A"))
        XCTAssertTrue(labels.contains("B"))
        XCTAssertTrue(labels.contains("E"))
        XCTAssertTrue(labels.contains("H"))
        XCTAssertTrue(labels.contains("K"))
        XCTAssertTrue(labels.contains("M"))
        XCTAssertTrue(labels.contains("N"))
        XCTAssertTrue(labels.contains("O"))
        XCTAssertTrue(labels.contains("P"))
        XCTAssertTrue(labels.contains("T"))
        XCTAssertTrue(labels.contains("X"))
        XCTAssertTrue(labels.contains("Y"))
        XCTAssertEqual(model.alphabetLetterRows[2].keys.last?.label, .formula(markup: #"a/\alpha"#, fallback: "a/α"))
    }

    func testCaseToggleChangesDisplayedLetterSet() {
        var model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        XCTAssertEqual(model.letterCase, .lowercase)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .symbol(markup: "q", fallback: "q"))

        model.toggleLetterCase()

        XCTAssertEqual(model.letterCase, .uppercase)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .symbol(markup: "Q", fallback: "Q"))
    }

    func testScriptToggleChangesLatinAndGreekSets() {
        var model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        XCTAssertEqual(model.alphabetScript, .latin)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .symbol(markup: "q", fallback: "q"))

        model.toggleAlphabetScript()

        XCTAssertEqual(model.alphabetScript, .greek)
        XCTAssertEqual(model.currentAlphabetKeys.first?.label, .symbol(markup: #"\alpha"#, fallback: "α"))
    }

    func testKeyLabelPresentationUsesDescriptorMarkupInsteadOfSynthesizingFromText() {
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "x", label: .symbol(markup: "x", fallback: "x"), intent: .input(.char("x")))
            ),
            .formulaMarkup("x")
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "sin", label: .formula(markup: #"\sin(x)"#, fallback: "sin(x)"), intent: .input(.function("sin")))
            ),
            .formulaMarkup(#"\sin(x)"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "theta", label: .symbol(markup: #"\theta"#, fallback: "θ"), intent: .action(.insertSymbol(#"\theta"#)))
            ),
            .formulaMarkup(#"\theta"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "pi", label: .symbol(markup: #"\pi"#, fallback: "π"), intent: .action(.insertSymbol(#"\pi"#)))
            ),
            .formulaMarkup(#"\pi"#)
        )
    }

    func testKeyLabelPresentationSupportsFormulaMarkupAndSystemLabels() {
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "sqrt", label: .formula(markup: #"\sqrt{x}"#, fallback: "√x"), intent: .input(.template(.sqrt)))
            ),
            .formulaMarkup(#"\sqrt{x}"#)
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "delete", label: .systemIcon("delete.left"), intent: .action(.deleteBackward))
            ),
            .systemImage("delete.left")
        )
    }

    func testSystemKeysDoNotUseFormulaPath() {
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "left", label: .systemIcon("arrow.left"), intent: .action(.moveLeft))
            ),
            .systemImage("arrow.left")
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "submit", label: .systemIcon("return.left"), intent: .action(.submit))
            ),
            .systemImage("return.left")
        )
    }

    func testLabelViewCanRenderAllSupportedLabelKinds() {
        let formula = MathInputKeyboardLabelView(
            key: .init(id: "fraction", label: .formula(markup: #"\frac{x}{y}"#, fallback: "x/y"), intent: .input(.template(.fraction))),
            style: .default,
            visualRole: .template
        )
        let text = MathInputKeyboardLabelView(
            key: .init(id: "x", label: .symbol(markup: "x", fallback: "x"), intent: .input(.char("x"))),
            style: .default,
            visualRole: .standard
        )
        let system = MathInputKeyboardLabelView(
            key: .init(id: "submit", label: .systemIcon("return.left"), intent: .action(.submit)),
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

        XCTAssertEqual(latin.key(for: MathInputKeyboardSurfaceModel.caseToggleKeyID)?.label, .formula(markup: "A/a", fallback: "A/a"))
        XCTAssertEqual(latin.key(for: MathInputKeyboardSurfaceModel.scriptToggleKeyID)?.label, .formula(markup: #"a/\alpha"#, fallback: "a/α"))
        XCTAssertEqual(greek.key(for: MathInputKeyboardSurfaceModel.caseToggleKeyID)?.label, .formula(markup: "A/a", fallback: "A/a"))
        XCTAssertEqual(greek.key(for: MathInputKeyboardSurfaceModel.scriptToggleKeyID)?.label, .formula(markup: #"a/\alpha"#, fallback: "a/α"))
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
        let sqrtPlan = FormulaDisplayEngine(metrics: metrics).getPlan(from: .init(rawValue: #"\sqrt{x}"#))
        let fractionPlan = FormulaDisplayEngine(metrics: metrics).getPlan(from: .init(rawValue: #"\frac{x}{y}"#))

        XCTAssertGreaterThan(sqrtPlan.size.width, 10)
        XCTAssertGreaterThan(sqrtPlan.size.height, 10)
        XCTAssertGreaterThan(fractionPlan.size.width, 10)
        XCTAssertGreaterThan(fractionPlan.size.height, 10)
    }

    func testKeyboardFormulaMetricsKeepDelimiterAndFunctionGapsVisible() {
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        let layoutEngine = FormulaLayoutEngine(metrics: metrics)

        let parenthesesBox = layoutEngine.layout(.parentheses(content: .anonymousPlaceholder))
        let absoluteValueBox = layoutEngine.layout(.absoluteValue(content: .anonymousPlaceholder))
        let functionBox = layoutEngine.layout(.function(name: "sin", arguments: [.anonymousPlaceholder]))

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
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: #"\begin{cases}x=x(t)\\y=y(t)\end{cases}"#),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: metrics
        )

        guard case .success(let measurement) = result else {
            return XCTFail("Expected compact parametric keyboard label to render through SwiftMath")
        }
        XCTAssertGreaterThan(measurement.width, 0)
        XCTAssertLessThan(measurement.width, 120)
    }

    func testAllStaticKeyboardFormulaLabelsAvoidEditingControlsAndRenderWithSwiftMath() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        let formulaLikeKeys = keys.filter { $0.label.staticMarkup != nil }

        XCTAssertFalse(formulaLikeKeys.isEmpty)
        XCTAssertTrue(formulaLikeKeys.allSatisfy { !$0.label.containsEditingControlMarkup })

        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        for key in formulaLikeKeys {
            guard let markup = key.label.staticMarkup else {
                continue
            }
            let result = FormulaReadOnlyRenderProbe.measure(
                markup: .init(rawValue: markup),
                options: .init(renderingBackend: .swiftMath, fontRole: .standard),
                metrics: metrics
            )

            switch result {
            case .success(let measurement):
                XCTAssertGreaterThan(measurement.width, 0, "Expected positive width for \(key.id)")
                XCTAssertGreaterThan(measurement.height, 0, "Expected positive height for \(key.id)")
            case .failure(_, let message):
                XCTFail("Expected SwiftMath keyboard label to render: \(key.id) \(markup) \(message)")
            }
        }
    }

    func testOnlySystemKeysRemainOutsideSwiftMathMathPath() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet"
        )

        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "system-delete", label: .systemIcon("delete.left"), intent: .action(.deleteBackward))
            ),
            .systemImage("delete.left")
        )
        XCTAssertTrue(model.currentAlphabetKeys.allSatisfy { $0.label.staticMarkup != nil })
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "toggle-case", label: .formula(markup: "A/a", fallback: "A/a"), intent: .none)
            ),
            .formulaMarkup("A/a")
        )
        XCTAssertEqual(
            MathInputKeyboardStyleBridge.presentation(
                for: .init(id: "toggle-script", label: .formula(markup: #"a/\alpha"#, fallback: "a/α"), intent: .none)
            ),
            .formulaMarkup(#"a/\alpha"#)
        )
    }

    func testUppercaseGreekLabelsParseThroughSwiftMath() {
        let model = MathInputKeyboardSurfaceModel(
            layout: MathKeyboardLayouts.standard,
            selectedPanelID: "alphabet",
            alphabetScript: .greek,
            letterCase: .uppercase
        )
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)

        for key in model.currentAlphabetKeys {
            guard let markup = key.label.staticMarkup else {
                return XCTFail("Expected uppercase Greek key to use static markup: \(key.id)")
            }
            let result = FormulaReadOnlyRenderProbe.measure(
                markup: .init(rawValue: markup),
                options: .init(renderingBackend: .swiftMath, fontRole: .standard),
                metrics: metrics
            )

            guard case .success(let measurement) = result else {
                return XCTFail("Expected uppercase Greek label to render: \(key.id) \(markup)")
            }
            XCTAssertGreaterThan(measurement.width, 0, "Expected positive width for \(key.id)")
            XCTAssertGreaterThan(measurement.height, 0, "Expected positive height for \(key.id)")
        }
    }

    func testAlphabetToggleLabelsRenderThroughSwiftMath() {
        let keys: [MathKeyboardKey] = [
            .init(id: "toggle-case", label: .formula(markup: "A/a", fallback: "A/a"), intent: .none),
            .init(id: "toggle-script", label: .formula(markup: #"a/\alpha"#, fallback: "a/α"), intent: .none)
        ]
        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .standard)

        for key in keys {
            guard let markup = key.label.staticMarkup else {
                return XCTFail("Expected toggle key to use static markup: \(key.id)")
            }
            let result = FormulaReadOnlyRenderProbe.measure(
                markup: .init(rawValue: markup),
                options: .init(renderingBackend: .swiftMath, fontRole: .standard),
                metrics: metrics
            )

            guard case .success(let measurement) = result else {
                return XCTFail("Expected toggle label to render: \(key.id) \(markup)")
            }
            XCTAssertGreaterThan(measurement.width, 0)
            XCTAssertGreaterThan(measurement.height, 0)
        }
    }

    func testSymbolsPanelRemovesGreekLettersAndUsesMathSymbolMarkup() {
        guard let symbolsPanel = MathKeyboardLayouts.standard.panels.first(where: { $0.id == "symbols" }) else {
            return XCTFail("Missing symbols panel")
        }

        let keys = symbolsPanel.rows.flatMap(\.keys)
        let ids = Set(keys.map(\.id))
        XCTAssertFalse(ids.contains("symbols-alpha"))
        XCTAssertFalse(ids.contains("symbols-beta"))
        XCTAssertFalse(ids.contains("symbols-theta"))
        XCTAssertTrue(keys.contains(where: { $0.id == "symbols-empty" && $0.label == .symbol(markup: #"\varnothing"#, fallback: "∅") }))
        XCTAssertTrue(keys.contains(where: { $0.id == "symbols-cdot" && $0.label == .symbol(markup: #"\cdot"#, fallback: "·") }))
        XCTAssertTrue(keys.contains(where: { $0.id == "symbols-approx" && $0.label == .symbol(markup: #"\approx"#, fallback: "≈") }))
        XCTAssertTrue(keys.contains(where: { $0.id == "symbols-pm" && $0.label == .symbol(markup: #"\pm"#, fallback: "±") }))
    }

    func testKeyboardMultiplicationLabelsUseTimesWhileFormulaDisplayUsesCdot() {
        let keys = MathKeyboardLayouts.standard.panels.flatMap(\.rows).flatMap(\.keys)
        XCTAssertTrue(keys.contains(where: { $0.id == "numbers-mul" && $0.label == .symbol(markup: #"\times"#, fallback: "×") }))
        XCTAssertTrue(keys.contains(where: { $0.id == "symbols-mul" && $0.label == .symbol(markup: #"\times"#, fallback: "×") }))
    }

    func testPiecewiseKeyboardLabelRendersThroughSwiftMath() {
        guard
            let functionsPanel = MathKeyboardLayouts.standard.panels.first(where: { $0.id == "functions" }),
            let piecewiseKey = functionsPanel.rows.flatMap(\.keys).first(where: { $0.id == "functions-piecewise" }),
            let markup = piecewiseKey.label.staticMarkup
        else {
            return XCTFail("Missing piecewise keyboard key")
        }

        let metrics = MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: .default, role: .template)
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: markup),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: metrics
        )

        guard case .success(let measurement) = result else {
            return XCTFail("Expected piecewise label to render")
        }
        XCTAssertGreaterThan(measurement.width, 0)
        XCTAssertGreaterThan(measurement.height, 0)
    }

    func testFunctionsPanelRemovesNonStructuralContentKeys() {
        guard let functionsPanel = MathKeyboardLayouts.standard.panels.first(where: { $0.id == "functions" }) else {
            return XCTFail("Missing functions panel")
        }

        let ids = Set(functionsPanel.rows.flatMap(\.keys).map(\.id))
        XCTAssertFalse(ids.contains("functions-open-paren"))
        XCTAssertFalse(ids.contains("functions-close-paren"))
        XCTAssertFalse(ids.contains("functions-x"))
        XCTAssertFalse(ids.contains("functions-y"))
        XCTAssertFalse(ids.contains("functions-t"))
        XCTAssertFalse(ids.contains("functions-e"))
        XCTAssertFalse(ids.contains("functions-plus"))
        XCTAssertFalse(ids.contains("functions-minus"))
    }

    func testActionConvenienceInitializerRemainsAvailable() {
        let view = MathInputKeyboardView { (_: KeyboardAction) in }
        XCTAssertNotNil(view)
    }

    private func formulaMarkup(_ key: MathKeyboardKey) -> String? {
        key.label.staticMarkup
    }
}
