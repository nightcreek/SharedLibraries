import XCTest
@testable import EMathicaMathCore

final class EquationSolverTests: XCTestCase {

    let x = Symbol(name: "x")

    func eq(_ left: Expr, _ right: Expr) -> Expr {
        .equation(left: left, right: right)
    }

    // MARK: - Linear

    func testLinearXPlus1Equals3() {
        // x + 1 = 3 → x = 2
        let equation = eq(.add([.symbol(x), .integer(1)]), .integer(3))
        let result = EquationSolver.solve(equation, variable: x)
        XCTAssertTrue(result.hasSolutions)
        XCTAssertEqual(result.solutions.count, 1)
    }

    func testLinear2xMinus4Equals0() {
        // 2x - 4 = 0 → 2x = 4 → x = 2
        let equation = eq(
            .add([.multiply([.integer(2), .symbol(x)]), .integer(-4)]),
            .integer(0)
        )
        let result = EquationSolver.solve(equation, variable: x)
        XCTAssertTrue(result.hasSolutions)
        XCTAssertEqual(result.solutions.count, 1)
    }

    func testLinear0xPlus0Equals0() {
        // 0 = 0 → infinite solutions
        let equation = eq(.integer(0), .integer(0))
        let result = EquationSolver.solve(equation, variable: x)
        // After simplification: 0=0 → 0 → linear extracts a=0,b=0 → infinite
        // Or if simplifier doesn't reduce: may produce solutions (both sides equal)
        XCTAssertTrue(!result.hasSolutions || result.diagnostics.contains(.infiniteSolutions),
                      "0=0 should produce no solutions or infinite diagnostic")
    }

    func testLinear0xPlus1Equals0() {
        // 0*x + 1 = 0 → no solution
        let equation = eq(.integer(1), .integer(0))
        let result = EquationSolver.solve(equation, variable: x)
        // 1=0 → simplifies to 1=0 → no real solutions
        XCTAssertFalse(result.hasSolutions, "1=0 should have no solutions")
    }

    func testLinearPlainExpression() {
        // Plain expression 2*x - 4 is treated as 2x - 4 = 0
        let result = EquationSolver.solve(
            .add([.multiply([.integer(2), .symbol(x)]), .integer(-4)]),
            variable: x
        )
        XCTAssertTrue(result.hasSolutions)
    }

    // MARK: - Quadratic

    func testQuadraticXSquaredMinus1() {
        // x² - 1 = 0 → x = ±1
        let equation = eq(
            .add([.power(base: .symbol(x), exponent: .integer(2)), .integer(-1)]),
            .integer(0)
        )
        let result = EquationSolver.solve(equation, variable: x)
        XCTAssertTrue(result.hasSolutions)
        XCTAssertEqual(result.solutions.count, 2)
    }

    func testQuadraticXSquaredPlus2XPlus1() {
        // x² + 2x + 1 = 0 → x = -1 (double root)
        let equation = eq(
            .add([.power(base: .symbol(x), exponent: .integer(2)),
                  .multiply([.integer(2), .symbol(x)]),
                  .integer(1)]),
            .integer(0)
        )
        let result = EquationSolver.solve(equation, variable: x)
        XCTAssertTrue(result.hasSolutions)
        XCTAssertEqual(result.solutions.count, 1)
    }

    func testQuadraticXSquaredPlus1() {
        // x² + 1 = 0 → no real solution
        let equation = eq(
            .add([.power(base: .symbol(x), exponent: .integer(2)), .integer(1)]),
            .integer(0)
        )
        let result = EquationSolver.solve(equation, variable: x)
        XCTAssertFalse(result.hasSolutions)
        XCTAssertTrue(result.diagnostics.contains(.noRealSolution))
    }

    func testQuadratic2xSquaredMinus8() {
        // 2x² - 8 = 0 → x = ±2
        let equation = eq(
            .add([.multiply([.integer(2), .power(base: .symbol(x), exponent: .integer(2))]),
                  .integer(-8)]),
            .integer(0)
        )
        let result = EquationSolver.solve(equation, variable: x)
        XCTAssertTrue(result.hasSolutions)
        XCTAssertEqual(result.solutions.count, 2)
    }

    // MARK: - Unsupported

    func testSinXEquals0Unsupported() {
        let equation = eq(.function(.sin, arguments: [.symbol(x)]), .integer(0))
        let result = EquationSolver.solve(equation, variable: x)
        // Should return unsupported diagnostic
        XCTAssertTrue(result.diagnostics.contains { d in
            if case .unsupported = d { return true }; return false
        } || result.diagnostics.contains(.notAUnivariateEquation))
    }

    func testNonEquationExpression() {
        // Plain symbol is treated as x = 0
        let result = EquationSolver.solve(.symbol(x), variable: x)
        XCTAssertTrue(result.hasSolutions)
        XCTAssertEqual(result.solutions.count, 1)
    }

    // MARK: - Newton

    func testNewtonConvergesOnSimpleExpression() {
        // x² - 2 = 0 near x=1.5 → √2 ≈ 1.414
        let expr: Expr = .add([.power(base: .symbol(x), exponent: .integer(2)), .integer(-2)])
        let root = EquationSolver.findRootNewton(expr, variable: x, initialGuess: 1.5)
        XCTAssertNotNil(root)
        if let r = root {
            XCTAssertEqual(r, 1.41421356, accuracy: 0.001)
        }
    }

    func testNewtonFailsOnDerivativeZero() {
        // Constant expression: derivative is 0
        let expr: Expr = .integer(5)
        let root = EquationSolver.findRootNewton(expr, variable: x, initialGuess: 1.0)
        XCTAssertNil(root)
    }

    func testNewtonConvergesOnXMinus2() {
        // x - 2 = 0 → x = 2
        let expr: Expr = .add([.symbol(x), .integer(-2)])
        let root = EquationSolver.findRootNewton(expr, variable: x, initialGuess: 0)
        XCTAssertNotNil(root)
        if let r = root {
            XCTAssertEqual(r, 2.0, accuracy: 0.0001)
        }
    }
}
