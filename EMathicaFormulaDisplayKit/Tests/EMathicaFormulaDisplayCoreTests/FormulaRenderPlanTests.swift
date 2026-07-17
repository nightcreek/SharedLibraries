import XCTest
@testable import EMathicaFormulaDisplayCore

final class FormulaRenderPlanTests: XCTestCase {
    private let engine = FormulaDisplayEngine()

    func testSimpleTextEmitsTextElement() {
        let plan = engine.getPlan(from: .init(rawValue: "x"))
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 {
                return text.text == "x"
            }
            return false
        })
    }

    func testOperatorEmitsOperatorTextElement() {
        let plan = engine.getPlan(from: .init(rawValue: "x+1"))
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 {
                return text.text == "+" && text.fontRole == .operatorSymbol
            }
            return false
        })
    }

    func testPlanSizeAndBaselineComeFromLayout() {
        let plan = engine.getPlan(from: .init(rawValue: "x+1"))
        guard let rootLayoutBox = plan.rootLayoutBox else {
            return XCTFail("Expected root layout box")
        }
        XCTAssertEqual(plan.size, plan.rootLayoutBox?.size)
        XCTAssertEqual(plan.baseline, rootLayoutBox.baseline, accuracy: 0.0001)
    }

    func testFractionEmitsFractionLine() {
        let plan = engine.getPlan(from: .init(rawValue: #"\frac{x}{2}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .line(let line) = $0 {
                return line.role == .fractionLine
            }
            return false
        })
    }

    func testFractionContainsNumeratorAndDenominatorText() {
        let plan = engine.getPlan(from: .init(rawValue: #"\frac{x}{2}"#))
        let texts = plan.elements.compactMap { element -> String? in
            if case .text(let text) = element { return text.text }
            return nil
        }
        XCTAssertTrue(texts.contains("x"))
        XCTAssertTrue(texts.contains("2"))
    }

    func testFractionLineYIsWithinPlanBounds() {
        let plan = engine.getPlan(from: .init(rawValue: #"\frac{x}{2}"#))
        guard let line = plan.elements.first(where: {
            if case .line(let line) = $0 { return line.role == .fractionLine }
            return false
        }), case .line(let lineElement) = line else {
            return XCTFail("Expected fraction line")
        }
        XCTAssertGreaterThanOrEqual(lineElement.frame.minY, plan.bounds.minY)
        XCTAssertLessThanOrEqual(lineElement.frame.maxY, plan.bounds.maxY)
    }

    func testSqrtEmitsRadicalElement() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{x}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .radical = $0 { return true }
            return false
        })
    }

    func testSqrtContainsRadicandTextElement() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{x}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 { return text.text == "x" }
            return false
        })
    }

    func testSuperscriptEmitsBaseAndExponentTextElements() {
        let plan = engine.getPlan(from: .init(rawValue: "x^2"))
        let texts = plan.elements.compactMap { element -> String? in
            if case .text(let text) = element { return text.text }
            return nil
        }
        XCTAssertTrue(texts.contains("x"))
        XCTAssertTrue(texts.contains("2"))
    }

    func testScriptPairEmitsBaseSubscriptAndSuperscriptTextElements() {
        let plan = engine.getPlan(from: .init(rawValue: "x_1^2"))
        let texts = plan.elements.compactMap { element -> String? in
            if case .text(let text) = element { return text.text }
            return nil
        }
        XCTAssertTrue(texts.contains("x"))
        XCTAssertTrue(texts.contains("1"))
        XCTAssertTrue(texts.contains("2"))
    }

    func testScriptTextElementsHaveValidFrames() {
        let plan = engine.getPlan(from: .init(rawValue: "x_1^2"))
        let frames = plan.elements.compactMap { element -> FormulaRect? in
            if case .text(let text) = element { return text.frame }
            return nil
        }
        XCTAssertFalse(frames.isEmpty)
        XCTAssertTrue(frames.allSatisfy { $0.size.width > 0 && $0.size.height > 0 })
    }

    func testCursorEmitsCursorElementAndRect() {
        let plan = engine.getPlan(from: .init(rawValue: #"\cursor{}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .cursor = $0 { return true }
            return false
        })
        XCTAssertEqual(plan.cursorRects.count, 1)
    }

    func testPlaceholderEmitsPlaceholderElementAndRect() {
        let plan = engine.getPlan(from: .init(rawValue: #"\placeholder{}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .placeholder = $0 { return true }
            return false
        })
        XCTAssertEqual(plan.placeholderRects.count, 1)
    }

    func testCursorPlaceholderSequenceEmitsBothMarkers() {
        let plan = engine.getPlan(from: .init(rawValue: #"\cursor{}\placeholder{}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .cursor = $0 { return true }
            return false
        })
        XCTAssertTrue(plan.elements.contains {
            if case .placeholder = $0 { return true }
            return false
        })
    }

    func testParenthesesEmitDelimiterElements() {
        let plan = engine.getPlan(from: .init(rawValue: "(x+1)"))
        let texts = plan.elements.compactMap { element -> String? in
            if case .text(let text) = element { return text.text }
            return nil
        }
        XCTAssertTrue(texts.contains("("))
        XCTAssertTrue(texts.contains(")"))
    }

    func testAbsoluteValueEmitsDelimiterElements() {
        let plan = engine.getPlan(from: .init(rawValue: "|x+1|"))
        XCTAssertGreaterThanOrEqual(plan.elements.filter {
            if case .line(let line) = $0 { return line.role == .delimiter }
            return false
        }.count, 2)
    }

    func testParametricPlanEmitsVisibleElements() {
        let plan = engine.getPlan(from: .init(rawValue: #"\parametric{x}{y}{t>0}"#))
        let texts = plan.elements.compactMap { element -> String? in
            if case .text(let text) = element { return text.text }
            return nil
        }
        XCTAssertTrue(texts.contains("x(t)="))
        XCTAssertTrue(texts.contains("y(t)="))
        XCTAssertTrue(texts.contains("x"))
        XCTAssertTrue(texts.contains("y"))
        XCTAssertEqual(plan.rootLayoutBox?.kind, .parametric2D)
    }

    func testPiecewisePlanEmitsBraceAndRowContent() {
        let plan = engine.getPlan(from: .init(rawValue: #"\piecewise{x}{x<0}{y}{x\geq0}"#))
        let delimiterCount = plan.elements.filter {
            if case .line(let line) = $0 { return line.role == .delimiter }
            return false
        }.count
        let texts = plan.elements.compactMap { element -> String? in
            if case .text(let text) = element { return text.text }
            return nil
        }
        XCTAssertGreaterThanOrEqual(delimiterCount, 3)
        XCTAssertTrue(texts.contains("x"))
        XCTAssertTrue(texts.contains("y"))
        XCTAssertEqual(plan.rootLayoutBox?.kind, .piecewise)
    }

    func testSimpleFormulaEmitsBounds() {
        let plan = engine.getPlan(from: .init(rawValue: "x+1"))
        XCTAssertGreaterThan(plan.bounds.size.width, 0)
        XCTAssertGreaterThan(plan.bounds.size.height, 0)
    }

    func testPlaceholderEmitsPlaceholderHitRegion() {
        let plan = engine.getPlan(from: .init(rawValue: #"\placeholder{}"#))
        XCTAssertTrue(plan.hitRegions.contains(where: { $0.kind == .placeholder }))
    }

    func testCursorEmitsCursorHitRegion() {
        let plan = engine.getPlan(from: .init(rawValue: #"\cursor{}"#))
        XCTAssertTrue(plan.hitRegions.contains(where: { $0.kind == .cursor }))
    }

    func testFractionEmitsStructureHitRegion() {
        let plan = engine.getPlan(from: .init(rawValue: #"\frac{x}{2}"#))
        XCTAssertTrue(plan.hitRegions.contains(where: { $0.kind == .structure }))
    }

    func testUnknownCommandStillEmitsVisibleFallbackElement() {
        let plan = engine.getPlan(from: .init(rawValue: #"\unknown{x}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 {
                return text.fontRole == .raw || text.fontRole == .error
            }
            return false
        })
    }

    func testMalformedFractionDoesNotCrashAndEmitsFallbackElement() {
        let plan = engine.getPlan(from: .init(rawValue: #"\frac{x}"#))
        XCTAssertFalse(plan.elements.isEmpty)
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 {
                return text.fontRole == .raw || text.fontRole == .error
            }
            return false
        })
    }
}
