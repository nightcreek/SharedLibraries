import XCTest
@testable import EMathicaMathCore

final class MathFunctionStringTests: XCTestCase {

    // MARK: - Known functions

    func testKnownSin() { XCTAssertEqual(MathFunction("sin"), .sin) }
    func testKnownCos() { XCTAssertEqual(MathFunction("cos"), .cos) }
    func testKnownTan() { XCTAssertEqual(MathFunction("tan"), .tan) }
    func testKnownExp() { XCTAssertEqual(MathFunction("exp"), .exp) }
    func testKnownLn() { XCTAssertEqual(MathFunction("ln"), .ln) }
    func testKnownSqrt() { XCTAssertEqual(MathFunction("sqrt"), .sqrt) }
    func testKnownAbs() { XCTAssertEqual(MathFunction("abs"), .abs) }
    func testKnownFloor() { XCTAssertEqual(MathFunction("floor"), .floor) }
    func testKnownCeil() { XCTAssertEqual(MathFunction("ceil"), .ceil) }

    // MARK: - Case insensitivity

    func testCaseInsensitiveSin() { XCTAssertEqual(MathFunction("SIN"), .sin) }
    func testCaseInsensitiveCos() { XCTAssertEqual(MathFunction("Cos"), .cos) }

    // MARK: - Aliases

    func testArcsinMapsToAsin() { XCTAssertEqual(MathFunction("arcsin"), .asin) }
    func testArccosMapsToAcos() { XCTAssertEqual(MathFunction("arccos"), .acos) }
    func testArctanMapsToAtan() { XCTAssertEqual(MathFunction("arctan"), .atan) }

    // MARK: - Log convention

    func testLnIsLn() { XCTAssertEqual(MathFunction("ln"), .ln) }
    func testLogIsNaturalLog() { XCTAssertEqual(MathFunction("log"), .log) }
    func testLgIsBase10() { XCTAssertEqual(MathFunction("lg"), .lg) }

    // MARK: - Unknown functions

    func testUnknownReturnsNil() {
        XCTAssertNil(MathFunction("nonsense"))
        XCTAssertNil(MathFunction("derivative"))
        XCTAssertNil(MathFunction(""))
    }

    // MARK: - toSemanticExpr basic conversion

    func testNumberConversion() {
        let ae = AlgebraExpression.number(5)
        XCTAssertEqual(ae.toSemanticExpr(), .integer(5))
    }

    func testSymbolConversion() {
        let ae = AlgebraExpression.symbol("x")
        XCTAssertEqual(ae.toSemanticExpr(), .symbol(Symbol(name: "x")))
    }

    func testAddConversion() {
        let ae = AlgebraExpression.add([.number(1), .number(2)])
        let result = ae.toSemanticExpr()
        // Should be .add([.integer(1), .integer(2)])
        if case .add(let terms) = result {
            XCTAssertEqual(terms.count, 2)
        } else {
            XCTFail("Expected .add")
        }
    }

    func testFunctionConversion() {
        let ae = AlgebraExpression.function("sin", .symbol("x"))
        let result = ae.toSemanticExpr()
        if case .function(let fn, let args) = result {
            XCTAssertEqual(fn, .sin)
            XCTAssertEqual(args.count, 1)
        } else {
            XCTFail("Expected .function")
        }
    }

    func testUnknownFunctionBecomesCustom() {
        let ae = AlgebraExpression.function("besselJ", .symbol("x"))
        let result = ae.toSemanticExpr()
        if case .function(let fn, let args) = result {
            if case .custom(let name) = fn {
                XCTAssertEqual(name, "besselJ")
            } else {
                XCTFail("Expected .custom")
            }
            XCTAssertEqual(args.count, 1)
        } else {
            XCTFail("Expected .function")
        }
    }
}
