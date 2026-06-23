public struct ExprDiagnosticList: Error, Equatable, Sendable {
    public var diagnostics: [ExprDiagnostic]

    public init(_ diagnostics: [ExprDiagnostic]) {
        self.diagnostics = diagnostics
    }
}

public struct QuadraticFormExtractionOptions: Equatable, Sendable {
    public var allowExpansion: Bool
    public var expansionOptions: PolynomialExpansionOptions

    public init(
        allowExpansion: Bool,
        expansionOptions: PolynomialExpansionOptions
    ) {
        self.allowExpansion = allowExpansion
        self.expansionOptions = expansionOptions
    }

    public static let strict = QuadraticFormExtractionOptions(
        allowExpansion: false,
        expansionOptions: .default2D
    )

    public static let expanded2D = QuadraticFormExtractionOptions(
        allowExpansion: true,
        expansionOptions: .default2D
    )
}

public struct QuadraticForm2D: Equatable, Sendable {
    public var xx: Double
    public var xy: Double
    public var yy: Double
    public var x: Double
    public var y: Double
    public var constant: Double

    public init(
        xx: Double = 0,
        xy: Double = 0,
        yy: Double = 0,
        x: Double = 0,
        y: Double = 0,
        constant: Double = 0
    ) {
        self.xx = xx
        self.xy = xy
        self.yy = yy
        self.x = x
        self.y = y
        self.constant = constant
    }
}

public struct QuadraticFormExtractor {
    private let normalizer: ExpressionNormalizer
    private let simplifier: ExpressionSimplifier
    private let evaluator: ExprEvaluator
    private let expander: PolynomialExpander

    public init(
        normalizer: ExpressionNormalizer = .init(),
        simplifier: ExpressionSimplifier = .init(),
        evaluator: ExprEvaluator = .init(),
        expander: PolynomialExpander = .init()
    ) {
        self.normalizer = normalizer
        self.simplifier = simplifier
        self.evaluator = evaluator
        self.expander = expander
    }

    public func extract(
        _ expr: Expr,
        xSymbol: Symbol = Symbol(name: "x", role: .variable),
        ySymbol: Symbol = Symbol(name: "y", role: .variable),
        options: QuadraticFormExtractionOptions = .strict
    ) -> Result<QuadraticForm2D, ExprDiagnosticList> {
        if options.allowExpansion {
            switch expander.expand(expr, options: options.expansionOptions) {
            case .success(let expanded):
                return extractStrict(expanded, xSymbol: xSymbol, ySymbol: ySymbol)
            case .failure(let diagnostics):
                return .failure(diagnostics)
            }
        }
        return extractStrict(expr, xSymbol: xSymbol, ySymbol: ySymbol)
    }

    private func extractStrict(
        _ expr: Expr,
        xSymbol: Symbol,
        ySymbol: Symbol
    ) -> Result<QuadraticForm2D, ExprDiagnosticList> {
        let preprocessed = simplifier.simplify(normalizer.normalize(expr))
        let terms: [Expr]
        if case .add(let flattened) = preprocessed {
            terms = flattened
        } else {
            terms = [preprocessed]
        }

        var coefficients = QuadraticForm2D()
        var diagnostics: [ExprDiagnostic] = []

        for term in terms {
            switch parseTerm(term, xSymbol: xSymbol, ySymbol: ySymbol) {
            case .success(let parsed):
                switch evaluateCoefficient(parsed.coefficient) {
                case .success(let value):
                    switch (parsed.xDegree, parsed.yDegree) {
                    case (2, 0):
                        coefficients.xx += value
                    case (1, 1):
                        coefficients.xy += value
                    case (0, 2):
                        coefficients.yy += value
                    case (1, 0):
                        coefficients.x += value
                    case (0, 1):
                        coefficients.y += value
                    case (0, 0):
                        coefficients.constant += value
                    default:
                        diagnostics.append(ExprDiagnostic(
                            severity: .error,
                            code: .unsupportedQuadraticTerm,
                            message: "unsupported monomial degree (\(parsed.xDegree), \(parsed.yDegree))"
                        ))
                    }
                case .failure(let error):
                    diagnostics.append(contentsOf: error.diagnostics)
                }
            case .failure(let error):
                diagnostics.append(contentsOf: error.diagnostics)
            }
        }

        if diagnostics.contains(where: { $0.severity == .error }) {
            return .failure(ExprDiagnosticList(diagnostics))
        }
        return .success(coefficients)
    }

    private struct ParsedTerm {
        var coefficient: Expr
        var xDegree: Int
        var yDegree: Int
    }

    private func parseTerm(
        _ term: Expr,
        xSymbol: Symbol,
        ySymbol: Symbol
    ) -> Result<ParsedTerm, ExprDiagnosticList> {
        switch term {
        case .integer, .rational, .decimal, .real, .constant:
            return .success(ParsedTerm(coefficient: term, xDegree: 0, yDegree: 0))

        case .symbol(let symbol):
            if symbol.name == xSymbol.name {
                return .success(ParsedTerm(coefficient: .integer(1), xDegree: 1, yDegree: 0))
            }
            if symbol.name == ySymbol.name {
                return .success(ParsedTerm(coefficient: .integer(1), xDegree: 0, yDegree: 1))
            }
            return .failure(diagnostic(
                code: .unexpectedSymbol,
                message: "unexpected symbol in quadratic term: \(symbol.name)"
            ))

        case .power(let base, let exponent):
            guard case .integer(let degree) = exponent else {
                return .failure(diagnostic(
                    code: .unsupportedQuadraticTerm,
                    message: "power exponent must be integer 1 or 2"
                ))
            }
            if degree < 0 {
                return .failure(diagnostic(
                    code: .unsupportedQuadraticTerm,
                    message: "negative degree is not supported"
                ))
            }
            if degree > 2 {
                return .failure(diagnostic(
                    code: .degreeTooHigh,
                    message: "degree \(degree) exceeds quadratic form"
                ))
            }

            guard case .symbol(let symbol) = base else {
                return .failure(diagnostic(
                    code: .unsupportedQuadraticTerm,
                    message: "power base must be x or y symbol"
                ))
            }
            if symbol.name == xSymbol.name {
                return .success(ParsedTerm(coefficient: .integer(1), xDegree: degree, yDegree: 0))
            }
            if symbol.name == ySymbol.name {
                return .success(ParsedTerm(coefficient: .integer(1), xDegree: 0, yDegree: degree))
            }
            return .failure(diagnostic(
                code: .unexpectedSymbol,
                message: "unexpected symbol in power term: \(symbol.name)"
            ))

        case .negate(let inner):
            switch parseTerm(inner, xSymbol: xSymbol, ySymbol: ySymbol) {
            case .success(let parsed):
                return .success(ParsedTerm(
                    coefficient: .negate(parsed.coefficient),
                    xDegree: parsed.xDegree,
                    yDegree: parsed.yDegree
                ))
            case .failure(let error):
                return .failure(error)
            }

        case .multiply(let factors):
            var coefficientFactors: [Expr] = []
            var xDegree = 0
            var yDegree = 0

            for factor in factors {
                switch parseTerm(factor, xSymbol: xSymbol, ySymbol: ySymbol) {
                case .success(let parsed):
                    xDegree += parsed.xDegree
                    yDegree += parsed.yDegree
                    coefficientFactors.append(parsed.coefficient)
                case .failure(let error):
                    return .failure(error)
                }
            }

            let totalDegree = xDegree + yDegree
            if totalDegree > 2 {
                return .failure(diagnostic(
                    code: .degreeTooHigh,
                    message: "term degree \(totalDegree) exceeds quadratic form"
                ))
            }

            let coefficient: Expr
            if coefficientFactors.isEmpty {
                coefficient = .integer(1)
            } else if coefficientFactors.count == 1 {
                coefficient = coefficientFactors[0]
            } else {
                coefficient = .multiply(coefficientFactors)
            }
            return .success(ParsedTerm(coefficient: coefficient, xDegree: xDegree, yDegree: yDegree))

        case .divide(let numerator, let denominator):
            switch (parseTerm(numerator, xSymbol: xSymbol, ySymbol: ySymbol),
                    parseTerm(denominator, xSymbol: xSymbol, ySymbol: ySymbol)) {
            case (.success(let n), .success(let d)):
                if d.xDegree != 0 || d.yDegree != 0 {
                    return .failure(diagnostic(
                        code: .unsupportedQuadraticTerm,
                        message: "denominator cannot contain x or y"
                    ))
                }
                return .success(ParsedTerm(
                    coefficient: .divide(numerator: n.coefficient, denominator: d.coefficient),
                    xDegree: n.xDegree,
                    yDegree: n.yDegree
                ))
            case (.failure(let error), _):
                return .failure(error)
            case (_, .failure(let error)):
                return .failure(error)
            }

        case .add:
            return .failure(diagnostic(
                code: .unsupportedQuadraticTerm,
                message: "term-level add requires explicit polynomial expansion"
            ))

        case .function:
            return .failure(diagnostic(
                code: .unsupportedQuadraticTerm,
                message: "function term is not supported in quadratic form extraction"
            ))

        case .equation, .relation, .chainedRelation, .piecewise, .tuple, .vector,
                .matrix, .assignment, .functionDefinition, .unknown:
            return .failure(diagnostic(
                code: .unsupportedQuadraticTerm,
                message: "expression kind is not supported in quadratic terms"
            ))
        }
    }

    private func evaluateCoefficient(_ coefficient: Expr) -> Result<Double, ExprDiagnosticList> {
        switch evaluator.evaluate(coefficient, environment: .init()) {
        case .value(let value):
            guard value.isFinite else {
                return .failure(diagnostic(
                    code: .unsupportedCoefficient,
                    message: "coefficient is not finite"
                ))
            }
            return .success(value)
        case .undefined(let issue):
            return .failure(diagnostic(
                code: .unsupportedCoefficient,
                message: "coefficient is not evaluable: \(issue.kind.rawValue)"
            ))
        }
    }

    private func diagnostic(code: ExprDiagnosticCode, message: String) -> ExprDiagnosticList {
        ExprDiagnosticList([ExprDiagnostic(
            severity: .error,
            code: code,
            message: message,
            location: nil
        )])
    }
}
