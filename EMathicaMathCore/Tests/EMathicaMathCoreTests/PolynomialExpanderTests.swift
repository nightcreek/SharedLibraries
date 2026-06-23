import Testing
@testable import EMathicaMathCore

struct PolynomialExpanderTests {
    private let expander = PolynomialExpander()
    private let extractor = QuadraticFormExtractor()
    private let x = Expr.symbol(Symbol(name: "x", role: .variable))
    private let y = Expr.symbol(Symbol(name: "y", role: .variable))

    @Test func linearExpressionRemainsEquivalent() throws {
        let expr = Expr.add([x, .integer(1)])
        let expanded = try requireExpanded(expr)
        let form = try requireExtracted(expanded)
        #expect(form.xx == 0)
        #expect(form.yy == 0)
        #expect(form.x == 1)
        #expect(form.constant == 1)
    }

    @Test func expandSquarePlusOne() throws {
        let expr = Expr.power(base: .add([x, .integer(1)]), exponent: .integer(2))
        let form = try requireExtracted(try requireExpanded(expr))
        #expect(form.xx == 1)
        #expect(form.x == 2)
        #expect(form.constant == 1)
    }

    @Test func expandSquareMinusOne() throws {
        let expr = Expr.power(base: .add([x, .integer(-1)]), exponent: .integer(2))
        let form = try requireExtracted(try requireExpanded(expr))
        #expect(form.xx == 1)
        #expect(form.x == -2)
        #expect(form.constant == 1)
    }

    @Test func expandProductConjugates() throws {
        let expr = Expr.multiply([
            .add([x, .integer(1)]),
            .add([x, .integer(-1)])
        ])
        let form = try requireExtracted(try requireExpanded(expr))
        #expect(form.xx == 1)
        #expect(form.x == 0)
        #expect(form.constant == -1)
    }

    @Test func expandShiftedCircleForm() throws {
        let expr = Expr.add([
            .power(base: .add([x, .integer(-1)]), exponent: .integer(2)),
            .power(base: .add([y, .integer(-2)]), exponent: .integer(2)),
            .integer(-9)
        ])
        let form = try requireExtracted(try requireExpanded(expr))
        #expect(form.xx == 1)
        #expect(form.yy == 1)
        #expect(form.x == -2)
        #expect(form.y == -4)
        #expect(form.constant == -4)
    }

    @Test func keepsXYTerm() throws {
        let expr = Expr.multiply([x, y])
        let form = try requireExtracted(try requireExpanded(expr))
        #expect(form.xy == 1)
    }

    @Test func rejectsDegreeTooHigh() throws {
        let expr = Expr.power(base: x, exponent: .integer(3))
        let diagnostics = try requireFailure(expr)
        #expect(diagnostics.contains(where: { $0.code == .expansionDegreeTooHigh }))
    }

    @Test func rejectsUnsupportedVariable() throws {
        let z = Expr.symbol(Symbol(name: "z", role: .variable))
        let expr = Expr.add([z, x])
        let diagnostics = try requireFailure(expr)
        #expect(diagnostics.contains(where: { $0.code == .unsupportedPolynomialVariable }))
    }

    @Test func rejectsFunctionTerm() throws {
        let expr = Expr.function(.sin, arguments: [x])
        let diagnostics = try requireFailure(expr)
        #expect(diagnostics.contains(where: { $0.code == .unsupportedPolynomialFactor }))
    }

    @Test func rejectsVariableDenominator() throws {
        let expr = Expr.divide(numerator: x, denominator: y)
        let diagnostics = try requireFailure(expr)
        #expect(diagnostics.contains(where: { $0.code == .variableDenominator }))
    }

    @Test func rejectsSymbolicCoefficient() throws {
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let expr = Expr.multiply([a, x])
        let diagnostics = try requireFailure(expr)
        #expect(diagnostics.contains(where: { $0.code == .nonNumericCoefficient || $0.code == .unsupportedPolynomialVariable }))
    }

    @Test func rejectsTermCountOverflow() throws {
        let expr = Expr.add([x, y, .integer(1)])
        let options = PolynomialExpansionOptions(
            maxDegree: 2,
            maxTermCount: 2,
            allowedVariables: PolynomialExpansionOptions.default2D.allowedVariables
        )
        let diagnostics = try requireFailure(expr, options: options)
        #expect(diagnostics.contains(where: { $0.code == .expansionTermLimitExceeded }))
    }

    @Test func expandedExprCanFeedQuadraticExtractor() throws {
        let expr = Expr.add([
            .power(base: .add([x, .integer(-1)]), exponent: .integer(2)),
            .power(base: .add([y, .integer(-2)]), exponent: .integer(2)),
            .integer(-9)
        ])
        let expanded = try requireExpanded(expr)
        let form = try requireExtracted(expanded)
        #expect(form.xx == 1)
        #expect(form.yy == 1)
        #expect(form.x == -2)
        #expect(form.y == -4)
        #expect(form.constant == -4)
    }
}

private func requireExpanded(
    _ expr: Expr,
    options: PolynomialExpansionOptions = .default2D
) throws -> Expr {
    let expander = PolynomialExpander()
    switch expander.expand(expr, options: options) {
    case .success(let expanded):
        return expanded
    case .failure(let diagnostics):
        Issue.record("Expected expansion success but failed: \(diagnostics.diagnostics)")
        throw TestFailure("unexpected expansion failure")
    }
}

private func requireFailure(
    _ expr: Expr,
    options: PolynomialExpansionOptions = .default2D
) throws -> [ExprDiagnostic] {
    let expander = PolynomialExpander()
    switch expander.expand(expr, options: options) {
    case .success(let expanded):
        Issue.record("Expected expansion failure but succeeded: \(expanded)")
        throw TestFailure("unexpected expansion success")
    case .failure(let diagnostics):
        return diagnostics.diagnostics
    }
}

private func requireExtracted(_ expr: Expr) throws -> QuadraticForm2D {
    switch QuadraticFormExtractor().extract(expr) {
    case .success(let form):
        return form
    case .failure(let diagnostics):
        Issue.record("Expected extractor success but failed: \(diagnostics.diagnostics)")
        throw TestFailure("unexpected extractor failure")
    }
}

private struct TestFailure: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
