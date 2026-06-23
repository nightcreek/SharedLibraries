import XCTest
@testable import EMathicaMathCore

final class SymbolicDifferentiatorTests: XCTestCase {

    let x = Symbol(name: "x")
    let y = Symbol(name: "y")

    func diff(_ expr: Expr) -> Expr? {
        SymbolicDifferentiator.differentiate(expr, withRespectTo: x)
    }

    // MARK: - Basic Rules

    func testConstantDerivative() {
        XCTAssertEqual(diff(.integer(5)), .integer(0))
        XCTAssertEqual(diff(.real(3.14)), .integer(0))
    }

    func testVariableDerivative() {
        XCTAssertEqual(diff(.symbol(x)), .integer(1))
        XCTAssertEqual(diff(.symbol(y)), .integer(0))
    }

    func testSumRule() {
        // d/dx (x + 3) = 1 + 0 = 1
        let result = diff(.add([.symbol(x), .integer(3)]))
        XCTAssertNotNil(result)
    }

    func testDifferenceRule() {
        // d/dx (x - 5) — represented as x + (-5)
        let result = diff(.add([.symbol(x), .integer(-5)]))
        XCTAssertNotNil(result)
    }

    // MARK: - Power Rule

    func testXSquared() {
        // d/dx x^2 = 2*x
        guard let result = diff(.power(base: .symbol(x), exponent: .integer(2))) else {
            XCTFail("Expected non-nil result")
            return
        }
        let printer = ExprDebugPrinter()
        let str = printer.print(result)
        // Should contain 2 and x
        XCTAssertTrue(str.contains("2"))
        XCTAssertTrue(str.contains("x") || str.contains("1")) // x may simplify to 1
    }

    func testXCubed() {
        // d/dx x^3 = 3*x^2
        guard let result = diff(.power(base: .symbol(x), exponent: .integer(3))) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        XCTAssertTrue(str.contains("3"))
    }

    func testConstantPower() {
        // d/dx 3^2 = 0 (structurally: n * u^(n-1) * u' = 2 * 3^1 * 0, which is 0 but not simplified atomically)
        let result = diff(.power(base: .integer(3), exponent: .integer(2)))
        XCTAssertNotNil(result)
        // The result should simplify to 0 after applying the simplifier
        let simplifier = ExpressionSimplifier()
        let simplified = simplifier.simplify(result!)
        XCTAssertEqual(simplified, .integer(0))
    }

    // MARK: - Product Rule

    func testXTimesX() {
        // d/dx (x * x) = 1*x + x*1 = 2x
        let result = diff(.multiply([.symbol(x), .symbol(x)]))
        XCTAssertNotNil(result)
    }

    // MARK: - Quotient Rule

    func testOneOverX() {
        // d/dx (1/x) = -1/x^2
        let result = diff(.divide(numerator: .integer(1), denominator: .symbol(x)))
        XCTAssertNotNil(result)
    }

    // MARK: - Trig Derivatives

    func testSinX() {
        // d/dx sin(x) = cos(x)
        guard let result = diff(.function(.sin, arguments: [.symbol(x)])) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        XCTAssertTrue(str.contains("cos"))
    }

    func testCosX() {
        // d/dx cos(x) = -sin(x)
        guard let result = diff(.function(.cos, arguments: [.symbol(x)])) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        XCTAssertTrue(str.contains("sin"))
    }

    func testTanX() {
        // d/dx tan(x) = sec^2(x)
        let result = diff(.function(.tan, arguments: [.symbol(x)]))
        XCTAssertNotNil(result)
    }

    // MARK: - Chain Rule

    func testSinOfXSquared() {
        // d/dx sin(x^2) = cos(x^2) * 2x
        let expr: Expr = .function(.sin, arguments: [
            .power(base: .symbol(x), exponent: .integer(2))
        ])
        guard let result = diff(expr) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        XCTAssertTrue(str.contains("cos"))
    }

    func testExpOfX() {
        // d/dx e^x = e^x
        guard let result = diff(.function(.exp, arguments: [.symbol(x)])) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        XCTAssertTrue(str.contains("exp") || str.contains("e"))
    }

    // MARK: - Ln / Sqrt

    func testLnX() {
        // d/dx ln(x) = 1/x
        guard let result = diff(.function(.ln, arguments: [.symbol(x)])) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        // Should be a division
        XCTAssertTrue(str.contains("/") || str.contains("divide"))
    }

    func testSqrtX() {
        // d/dx sqrt(x) = 1/(2*sqrt(x))
        guard let result = diff(.function(.sqrt, arguments: [.symbol(x)])) else {
            XCTFail("Expected non-nil")
            return
        }
        let str = ExprDebugPrinter().print(result)
        XCTAssertTrue(str.contains("/") || str.contains("divide") || str.contains("sqrt"))
    }

    // MARK: - Negate

    func testNegateX() {
        // d/dx (-x) = -1
        let result = diff(.negate(.symbol(x)))
        XCTAssertNotNil(result)
    }

    // MARK: - Unsupported

    func testAbsXReturnsNil() {
        let result = diff(.function(.abs, arguments: [.symbol(x)]))
        XCTAssertNil(result)
    }

    func testPiecewiseReturnsNil() {
        let expr: Expr = .piecewise(branches: [], otherwise: .symbol(x))
        let result = diff(expr)
        XCTAssertNil(result)
    }
}
