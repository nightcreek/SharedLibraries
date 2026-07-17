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

    func testSqrtEmitsRadicalGlyphElement() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{x}"#))
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 {
                return text.text == "√" && text.fontRole == .radicalGlyph
            }
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

    func testSqrtEmitsOverlineLineNearRadicand() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{\frac{1}{2}}"#))
        guard
            let rootBox = plan.rootLayoutBox,
            let radicandChild = rootBox.children.first
        else {
            return XCTFail("Expected sqrt child layout")
        }
        let radicandBounds = radicandChild.box.bounds.offsetBy(dx: radicandChild.origin.x, dy: radicandChild.origin.y)
        guard let glyph = plan.elements.first(where: {
            if case .text(let text) = $0 {
                return text.text == "√" && text.fontRole == .radicalGlyph
            }
            return false
        }), case .text(let glyphElement) = glyph else {
            return XCTFail("Expected radical glyph element")
        }
        let overlines = plan.elements.compactMap { element -> FormulaLineElement? in
            if case .line(let line) = element, line.role == .radical {
                return line
            }
            return nil
        }
        guard let overline = overlines.first else {
            return XCTFail("Expected radical overline")
        }

        XCTAssertGreaterThan(glyphElement.frame.size.width, 0)
        XCTAssertGreaterThan(glyphElement.frame.size.height, 0)
        XCTAssertLessThan(glyphElement.frame.maxX, radicandBounds.minX)
        XCTAssertGreaterThan(radicandBounds.minX - glyphElement.frame.maxX, 0)
        XCTAssertLessThan(radicandBounds.minX - glyphElement.frame.maxX, 1.2)
        XCTAssertGreaterThanOrEqual(glyphElement.frame.minX, plan.bounds.minX)
        XCTAssertLessThanOrEqual(glyphElement.frame.maxX, plan.bounds.maxX)
        XCTAssertLessThanOrEqual(glyphElement.frame.minY, plan.bounds.maxY)
        XCTAssertGreaterThanOrEqual(glyphElement.frame.maxY, plan.bounds.minY)
        XCTAssertGreaterThanOrEqual(glyphElement.frame.size.width, FormulaLayoutMetrics.default.baseFontSize * 0.32)
        XCTAssertLessThanOrEqual(abs(overline.frame.minX - radicandBounds.minX), 0.3)
        XCTAssertGreaterThanOrEqual(overline.frame.maxX, radicandBounds.maxX)
        XCTAssertEqual(overline.frame.size.height, FormulaLayoutMetrics.default.fractionLineThickness, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(glyphElement.frame.minY, overline.frame.minY)
    }

    func testSqrtPlaceholderGlyphAndOverlineStayCompact() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{\placeholder{}}"#))
        guard
            let rootBox = plan.rootLayoutBox,
            let radicandChild = rootBox.children.first
        else {
            return XCTFail("Expected sqrt child layout")
        }
        let radicandBounds = radicandChild.box.bounds.offsetBy(dx: radicandChild.origin.x, dy: radicandChild.origin.y)
        guard let glyph = plan.elements.first(where: {
            if case .text(let text) = $0 {
                return text.text == "√" && text.fontRole == .radicalGlyph
            }
            return false
        }), case .text(let glyphElement) = glyph else {
            return XCTFail("Expected radical glyph element")
        }
        let overlines = plan.elements.compactMap { element -> FormulaLineElement? in
            if case .line(let line) = element, line.role == .radical {
                return line
            }
            return nil
        }
        guard let overline = overlines.first else {
            return XCTFail("Expected radical overline")
        }
        XCTAssertGreaterThanOrEqual(glyphElement.frame.minX, plan.bounds.minX)
        XCTAssertLessThanOrEqual(glyphElement.frame.maxX, plan.bounds.maxX)
        XCTAssertGreaterThanOrEqual(glyphElement.frame.size.width, FormulaLayoutMetrics.default.baseFontSize * 0.32)
        XCTAssertLessThan(glyphElement.frame.maxX, radicandBounds.minX)
        XCTAssertLessThan(radicandBounds.minX - glyphElement.frame.maxX, 1.2)
        XCTAssertGreaterThan(overline.frame.size.width, 4)
        XCTAssertFalse(plan.elements.contains {
            if case .radical = $0 { return true }
            return false
        })
    }

    func testSqrtGlyphFrameStaysFullyInsidePlanBounds() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{xxxxx}"#))
        guard let glyph = plan.elements.first(where: {
            if case .text(let text) = $0 {
                return text.text == "√" && text.fontRole == .radicalGlyph
            }
            return false
        }), case .text(let glyphElement) = glyph else {
            return XCTFail("Expected radical glyph element")
        }

        XCTAssertGreaterThanOrEqual(glyphElement.frame.minX, plan.bounds.minX)
        XCTAssertLessThanOrEqual(glyphElement.frame.maxX, plan.bounds.maxX)
        XCTAssertGreaterThanOrEqual(glyphElement.frame.minY, plan.bounds.minY)
        XCTAssertLessThanOrEqual(glyphElement.frame.maxY, plan.bounds.maxY)
    }

    func testSqrtGlyphAndOverlineRenderAfterRadicandContent() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{\placeholder{}}"#))

        guard
            let placeholderIndex = plan.elements.firstIndex(where: {
                if case .placeholder = $0 { return true }
                return false
            }),
            let glyphIndex = plan.elements.firstIndex(where: {
                if case .text(let text) = $0 {
                    return text.text == "√" && text.fontRole == .radicalGlyph
                }
                return false
            }),
            let overlineIndex = plan.elements.firstIndex(where: {
                if case .line(let line) = $0 {
                    return line.role == .radical
                }
                return false
            })
        else {
            return XCTFail("Expected sqrt placeholder, glyph, and overline")
        }

        XCTAssertGreaterThan(glyphIndex, placeholderIndex)
        XCTAssertGreaterThan(overlineIndex, placeholderIndex)
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

    func testParenthesesDelimiterFramesStayCompact() {
        let plan = engine.getPlan(from: .init(rawValue: #"(\placeholder{})"#))
        let delimiterFrames = plan.elements.compactMap { element -> FormulaRect? in
            if case .text(let text) = element, text.text == "(" || text.text == ")" {
                return text.frame
            }
            return nil
        }
        XCTAssertEqual(delimiterFrames.count, 2)
        XCTAssertTrue(delimiterFrames.allSatisfy { $0.size.width < plan.size.width * 0.22 })
    }

    func testAbsoluteValueDelimiterStaysThin() {
        let plan = engine.getPlan(from: .init(rawValue: #"|\placeholder{}|"#))
        let delimiterFrames = plan.elements.compactMap { element -> FormulaRect? in
            if case .line(let line) = element, line.role == .delimiter {
                return line.frame
            }
            return nil
        }
        XCTAssertEqual(delimiterFrames.count, 2)
        XCTAssertTrue(delimiterFrames.allSatisfy { $0.size.width <= 0.75 })
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

    func testNestedSqrtPlaceholderRemainsVisible() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{\placeholder{}}"#))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
    }

    func testNestedFractionPlaceholdersRemainVisible() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{\frac{\placeholder{}}{\placeholder{}}}"#))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertGreaterThanOrEqual(plan.placeholderRects.count, 2)
        XCTAssertTrue(plan.elements.contains {
            if case .text(let text) = $0 {
                return text.text == "√" && text.fontRole == .radicalGlyph
            }
            return false
        })
    }

    func testParenthesesPlaceholderRemainsVisible() {
        let plan = engine.getPlan(from: .init(rawValue: #"(\placeholder{})"#))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
    }

    func testAbsoluteValueSqrtPlaceholderRemainsVisible() {
        let plan = engine.getPlan(from: .init(rawValue: #"|\sqrt{\placeholder{}}|"#))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
        XCTAssertGreaterThanOrEqual(plan.elements.filter {
            if case .line(let line) = $0 { return line.role == .delimiter }
            return false
        }.count, 2)
    }

    func testEmptyNestedSuperscriptRemainsVisible() {
        let plan = engine.getPlan(from: .init(rawValue: #"x^{\placeholder{}}"#))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
    }

    func testSqrtRadicandOffsetStaysBelowUpperBound() {
        let plan = engine.getPlan(from: .init(rawValue: #"\sqrt{\placeholder{}}"#))
        guard
            let root = plan.rootLayoutBox,
            let radicandChild = root.children.first
        else {
            return XCTFail("Expected sqrt layout child")
        }
        XCTAssertGreaterThan(radicandChild.origin.x, 0)
        XCTAssertLessThan(radicandChild.origin.x, root.size.width * 0.38)
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
