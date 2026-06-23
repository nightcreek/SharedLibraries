import XCTest
@testable import EMathicaMathCore

final class ExprSerializerTests: XCTestCase {

    // MARK: - Basic serialization

    func testSerializeInteger() {
        XCTAssertEqual(ExprSerializer.serialize(.integer(5)), "5")
    }

    func testSerializeSymbol() {
        XCTAssertEqual(ExprSerializer.serialize(.symbol(Symbol(name: "x"))), "x")
    }

    func testSerializeAdd() {
        let expr: Expr = .add([.symbol(Symbol(name: "x")), .integer(3)])
        let result = ExprSerializer.serialize(expr)
        XCTAssertTrue(result?.contains("x") ?? false)
        XCTAssertTrue(result?.contains("3") ?? false)
    }

    func testSerializeMultiply() {
        let expr: Expr = .multiply([.integer(2), .symbol(Symbol(name: "x"))])
        let result = ExprSerializer.serialize(expr)
        XCTAssertTrue(result?.contains("2") ?? false)
        XCTAssertTrue(result?.contains("x") ?? false)
        // Number*identifier omits "*": 2*x → 2x
        XCTAssertEqual(result, "2x")
    }

    func testSerializeDivide() {
        let expr: Expr = .divide(numerator: .integer(1), denominator: .symbol(Symbol(name: "x")))
        let result = ExprSerializer.serialize(expr)
        XCTAssertEqual(result, "1/x")
    }

    func testSerializePower() {
        let expr: Expr = .power(base: .symbol(Symbol(name: "x")), exponent: .integer(2))
        let result = ExprSerializer.serialize(expr)
        XCTAssertEqual(result, "x^2")
    }

    func testSerializeNegate() {
        let expr: Expr = .negate(.symbol(Symbol(name: "x")))
        let result = ExprSerializer.serialize(expr)
        XCTAssertEqual(result, "-x")
    }

    func testSerializeSin() {
        let expr: Expr = .function(.sin, arguments: [.symbol(Symbol(name: "x"))])
        XCTAssertEqual(ExprSerializer.serialize(expr), "sin(x)")
    }

    func testSerializeCos() {
        let expr: Expr = .function(.cos, arguments: [.symbol(Symbol(name: "x"))])
        XCTAssertEqual(ExprSerializer.serialize(expr), "cos(x)")
    }

    func testSerializeExp() {
        let expr: Expr = .function(.exp, arguments: [.symbol(Symbol(name: "x"))])
        XCTAssertEqual(ExprSerializer.serialize(expr), "exp(x)")
    }

    func testSerializeLn() {
        let expr: Expr = .function(.ln, arguments: [.symbol(Symbol(name: "x"))])
        XCTAssertEqual(ExprSerializer.serialize(expr), "ln(x)")
    }

    func testSerializeSqrt() {
        let expr: Expr = .function(.sqrt, arguments: [.symbol(Symbol(name: "x"))])
        XCTAssertEqual(ExprSerializer.serialize(expr), "sqrt(x)")
    }

    // MARK: - Derivative round-trip

    func testDerivativeXSquaredRoundTrip() {
        let x = Symbol(name: "x")
        // d/dx x^2 = 2*x
        guard let derivative = SymbolicDifferentiator.differentiate(
            .power(base: .symbol(x), exponent: .integer(2)), withRespectTo: x
        ) else {
            XCTFail("Differentiation failed")
            return
        }
        let simplified = ExpressionSimplifier().simplify(derivative)
        let normalized = ExpressionNormalizer().normalize(simplified)
        guard let serialized = ExprSerializer.serialize(normalized) else {
            XCTFail("Serialization failed")
            return
        }
        // The serialized form should be parseable — verify it's non-empty and reasonable
        XCTAssertFalse(serialized.isEmpty)
        XCTAssertTrue(serialized.contains("x"))
    }

    func testDerivativeSinXRoundTrip() {
        let x = Symbol(name: "x")
        guard let derivative = SymbolicDifferentiator.differentiate(
            .function(.sin, arguments: [.symbol(x)]), withRespectTo: x
        ) else {
            XCTFail("Differentiation failed")
            return
        }
        let simplified = ExpressionSimplifier().simplify(derivative)
        let normalized = ExpressionNormalizer().normalize(simplified)
        guard let serialized = ExprSerializer.serialize(normalized) else {
            XCTFail("Serialization failed")
            return
        }
        XCTAssertTrue(serialized.contains("cos"))
        XCTAssertTrue(serialized.contains("x"))
    }

    func testDerivativeQuotientRoundTrip() {
        let x = Symbol(name: "x")
        // d/dx (x^2 + 1) / x
        let num: Expr = .add([.power(base: .symbol(x), exponent: .integer(2)), .integer(1)])
        let expr: Expr = .divide(numerator: num, denominator: .symbol(x))
        guard let derivative = SymbolicDifferentiator.differentiate(expr, withRespectTo: x) else {
            XCTFail("Differentiation failed")
            return
        }
        let simplified = ExpressionSimplifier().simplify(derivative)
        let normalized = ExpressionNormalizer().normalize(simplified)
        guard let serialized = ExprSerializer.serialize(normalized) else {
            XCTFail("Serialization failed")
            return
        }
        XCTAssertFalse(serialized.isEmpty)
    }

    // MARK: - Unsupported returns nil

    func testPiecewiseReturnsNil() {
        let expr: Expr = .piecewise(branches: [], otherwise: .integer(0))
        XCTAssertNil(ExprSerializer.serialize(expr))
    }

    func testEquationReturnsNil() {
        let x = Symbol(name: "x")
        let expr: Expr = .equation(left: .symbol(x), right: .integer(0))
        XCTAssertNil(ExprSerializer.serialize(expr))
    }
}
