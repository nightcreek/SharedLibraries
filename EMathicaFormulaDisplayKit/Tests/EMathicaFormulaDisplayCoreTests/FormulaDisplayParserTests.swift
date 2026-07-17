import XCTest
@testable import EMathicaFormulaDisplayCore

final class FormulaDisplayParserTests: XCTestCase {
    private let parser = FormulaDisplayParser()

    func testParsesSimpleSequence() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: "x+1")),
            .sequence([
                .text("x", role: .symbol),
                .operatorSymbol("+"),
                .text("1", role: .number)
            ])
        )
    }

    func testParsesNumber() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: "123")),
            .text("123", role: .number)
        )
    }

    func testParsesSuperscriptForms() {
        let compact = parser.parse(.init(rawValue: "x^2"))
        let braced = parser.parse(.init(rawValue: "x^{2}"))

        let expected: FormulaDisplayNode = .superscript(
            base: .text("x", role: .symbol),
            exponent: .text("2", role: .number)
        )

        XCTAssertEqual(compact, expected)
        XCTAssertEqual(braced, expected)
    }

    func testParsesSubscriptForms() {
        let compact = parser.parse(.init(rawValue: "x_1"))
        let braced = parser.parse(.init(rawValue: "x_{1}"))

        let expected: FormulaDisplayNode = .subscript(
            base: .text("x", role: .symbol),
            subscriptNode: .text("1", role: .number)
        )

        XCTAssertEqual(compact, expected)
        XCTAssertEqual(braced, expected)
    }

    func testParsesScriptPairInBothOrders() {
        let expected: FormulaDisplayNode = .scriptPair(
            base: .text("x", role: .symbol),
            subscriptNode: .text("1", role: .number),
            superscriptNode: .text("2", role: .number)
        )

        XCTAssertEqual(parser.parse(.init(rawValue: "x_1^2")), expected)
        XCTAssertEqual(parser.parse(.init(rawValue: "x^2_1")), expected)
        XCTAssertEqual(parser.parse(.init(rawValue: "x_{1}^{2}")), expected)
        XCTAssertEqual(parser.parse(.init(rawValue: "x^{2}_{1}")), expected)
    }

    func testParsesFraction() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\frac{x}{2}"#)),
            .fraction(
                numerator: .text("x", role: .symbol),
                denominator: .text("2", role: .number)
            )
        )
    }

    func testParsesNestedFraction() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\frac{\frac{x}{2}}{3}"#)),
            .fraction(
                numerator: .fraction(
                    numerator: .text("x", role: .symbol),
                    denominator: .text("2", role: .number)
                ),
                denominator: .text("3", role: .number)
            )
        )
    }

    func testParsesSqrt() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\sqrt{x}"#)),
            .sqrt(radicand: .text("x", role: .symbol))
        )
    }

    func testParsesFunctions() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\sin{x}"#)),
            .function(name: "sin", arguments: [.text("x", role: .symbol)])
        )

        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\sin(x)"#)),
            .function(name: "sin", arguments: [.text("x", role: .symbol)])
        )

        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\log{10}{x}"#)),
            .function(
                name: "log",
                arguments: [
                    .text("10", role: .number),
                    .text("x", role: .symbol)
                ]
            )
        )

        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\log(x)"#)),
            .function(
                name: "log",
                arguments: [.text("x", role: .symbol)]
            )
        )
    }

    func testParsesGreekSymbolCommands() {
        let expectedPairs: [(String, String)] = [
            (#"\alpha"#, "α"),
            (#"\epsilon"#, "ε"),
            (#"\theta"#, "θ"),
            (#"\pi"#, "π"),
            (#"\omega"#, "ω"),
            (#"\Gamma"#, "Γ"),
            (#"\Theta"#, "Θ"),
            (#"\Omega"#, "Ω")
        ]

        for (command, symbol) in expectedPairs {
            XCTAssertEqual(
                parser.parse(.init(rawValue: command)),
                .text(symbol, role: .symbol),
                "Expected \(command) to render as \(symbol)"
            )
        }
    }

    func testParsesOperatorSymbolCommands() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\times"#)),
            .operatorSymbol("×")
        )
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\div"#)),
            .operatorSymbol("÷")
        )
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\leq"#)),
            .operatorSymbol("≤")
        )
    }

    func testParsesParentheses() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: "(x+1)")),
            .parentheses(
                content: .sequence([
                    .text("x", role: .symbol),
                    .operatorSymbol("+"),
                    .text("1", role: .number)
                ])
            )
        )
    }

    func testParsesAbsoluteValue() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: "|x+1|")),
            .absoluteValue(
                content: .sequence([
                    .text("x", role: .symbol),
                    .operatorSymbol("+"),
                    .text("1", role: .number)
                ])
            )
        )
    }

    func testParsesCursorAndPlaceholderForms() {
        XCTAssertEqual(parser.parse(.init(rawValue: #"\cursor{}"#)), .cursor)
        XCTAssertEqual(parser.parse(.init(rawValue: #"\placeholder{}"#)), .placeholder)
        XCTAssertEqual(parser.parse(.init(rawValue: "□")), .placeholder)
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\cursor{}\placeholder{}"#)),
            .sequence([.cursor, .placeholder])
        )
    }

    func testParsesMathInputStyleEditDisplay() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\frac{x}{\cursor{}\placeholder{}}"#)),
            .fraction(
                numerator: .text("x", role: .symbol),
                denominator: .sequence([.cursor, .placeholder])
            )
        )
    }

    func testParsesParametricCommand() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\parametric{x(t)}{y(t)}{t>0}"#)),
            .parametric2D(
                x: .sequence([
                    .text("x", role: .symbol),
                    .parentheses(
                        content: .text("t", role: .symbol)
                    )
                ]),
                y: .sequence([
                    .text("y", role: .symbol),
                    .parentheses(
                        content: .text("t", role: .symbol)
                    )
                ]),
                range: .sequence([
                    .text("t", role: .symbol),
                    .operatorSymbol(">"),
                    .text("0", role: .number)
                ])
            )
        )
    }

    func testParsesPiecewiseCommand() {
        XCTAssertEqual(
            parser.parse(.init(rawValue: #"\piecewise{x}{x<0}{y}{x\geq0}"#)),
            .piecewise(
                rows: [
                    .init(
                        expression: .text("x", role: .symbol),
                        condition: .sequence([
                            .text("x", role: .symbol),
                            .operatorSymbol("<"),
                            .text("0", role: .number)
                        ])
                    ),
                    .init(
                        expression: .text("y", role: .symbol),
                        condition: .sequence([
                            .text("x", role: .symbol),
                            .operatorSymbol("≥"),
                            .text("0", role: .number)
                        ])
                    )
                ]
            )
        )
    }

    func testUnknownCommandFallsBackWithoutCrash() {
        let node = parser.parse(.init(rawValue: #"\unknown{x}"#))
        guard case .error(let error) = node else {
            return XCTFail("Expected error fallback, got \(node)")
        }
        XCTAssertEqual(error.kind, .unknownCommand)
        XCTAssertEqual(error.rawText, #"\unknown{x}"#)
    }

    func testUnmatchedBraceFallsBackWithoutCrash() {
        let node = parser.parse(.init(rawValue: #"\frac{x}{2"#))
        guard case .fraction(let numerator, let denominator) = node else {
            return XCTFail("Expected partial fraction fallback, got \(node)")
        }
        XCTAssertEqual(numerator, .text("x", role: .symbol))
        guard case .error(let error) = denominator else {
            return XCTFail("Expected denominator error fallback, got \(denominator)")
        }
        XCTAssertEqual(error.kind, .unmatchedBrace)
        XCTAssertEqual(error.rawText, "{2")
    }

    func testMalformedFractionFallsBackWithoutCrash() {
        let node = parser.parse(.init(rawValue: #"\frac{x}"#))
        guard case .error(let error) = node else {
            return XCTFail("Expected error fallback, got \(node)")
        }
        XCTAssertEqual(error.kind, .malformedFraction)
        XCTAssertEqual(error.rawText, #"\frac{x}"#)
    }

    func testMalformedScriptFallsBackWithoutCrash() {
        let node = parser.parse(.init(rawValue: "x^"))
        XCTAssertEqual(
            node,
            .sequence([
                .text("x", role: .symbol),
                .error(.init(kind: .malformedScript, rawText: "^"))
            ])
        )
    }

    func testUnmatchedAbsoluteValueFallsBackWithoutCrash() {
        let node = parser.parse(.init(rawValue: "|x+1"))
        guard case .error(let error) = node else {
            return XCTFail("Expected error fallback, got \(node)")
        }
        XCTAssertEqual(error.kind, .unmatchedDelimiter)
        XCTAssertEqual(error.rawText, "|x+1")
    }
}
