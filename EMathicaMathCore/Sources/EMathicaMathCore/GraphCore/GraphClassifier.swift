import Foundation

public struct GraphClassifier {
    private let normalizer: ExpressionNormalizer
    private let simplifier: ExpressionSimplifier
    private let parameterSymbolNames: Set<String>

    public init(
        normalizer: ExpressionNormalizer = .init(),
        simplifier: ExpressionSimplifier = .init(),
        parameterSymbolNames: Set<String> = []
    ) {
        self.normalizer = normalizer
        self.simplifier = simplifier
        self.parameterSymbolNames = parameterSymbolNames
    }

    public func classify(_ expr: Expr) -> GraphClassificationResult {
        let normalized = normalizer.normalize(expr)
        let simplified = simplifier.simplify(normalized)
        return classifySimplified(simplified)
    }

    private func classifySimplified(_ expr: Expr) -> GraphClassificationResult {
        switch expr {
        case .equation(let left, let right):
            return classifyEquation(left: left, right: right)
        case .relation:
            return classifyRelation(expr)
        case .chainedRelation:
            return GraphClassificationResult(intent: .implicit(relation: expr))
        case .tuple(let values):
            return classifyTuple(values, source: expr)
        case .piecewise(let branches, _):
            return classifyPiecewise(branches)
        case .function(let function, let arguments):
            return classifyFunction(function, arguments: arguments, source: expr)
        case .unknown:
            return GraphClassificationResult(
                intent: .unknown(expr),
                diagnostics: [diag(.unsupportedExpression, "无法识别表达式图形意图")]
            )
        default:
            return GraphClassificationResult(
                intent: .explicitY(expression: expr, variable: Symbol(name: "x", role: .variable))
            )
        }
    }

    private func classifyEquation(left: Expr, right: Expr) -> GraphClassificationResult {
        let equationExpr = Expr.equation(left: left, right: right)
        if let namedPoint = classifyNamedPointEquation(left: left, right: right) {
            return GraphClassificationResult(intent: namedPoint)
        }
        if let circleIntent = classifyOriginCircleIntent(left: left, right: right) {
            return GraphClassificationResult(intent: circleIntent)
        }
        if let translatedCircleIntent = classifyTranslatedCircleIntent(left: left, right: right) {
            return GraphClassificationResult(intent: translatedCircleIntent)
        }
        if let conicIntent = classifyStandardOriginConicIntent(left: left, right: right, source: .equation(left: left, right: right)) {
            return GraphClassificationResult(intent: conicIntent)
        }
        if let translatedConicIntent = classifyStandardTranslatedConicIntent(left: left, right: right, source: .equation(left: left, right: right)) {
            return GraphClassificationResult(intent: translatedConicIntent)
        }
        if isSymbol(left, named: "r") {
            return classifyPolarRadius(radiusExpr: right, source: .equation(left: left, right: right))
        }

        if isSymbol(left, named: "y") {
            let vars = variableNames(in: right)
            if vars.isEmpty || vars == ["x"] {
                return GraphClassificationResult(
                    intent: .explicitY(expression: right, variable: Symbol(name: "x", role: .variable))
                )
            }
            return GraphClassificationResult(intent: .implicit(relation: equationExpr))
        }

        if isSymbol(left, named: "x") {
            let vars = variableNames(in: right)
            if vars.isEmpty || vars == ["y"] {
                return GraphClassificationResult(
                    intent: .explicitX(expression: right, variable: Symbol(name: "y", role: .variable))
                )
            }
            return GraphClassificationResult(intent: .implicit(relation: equationExpr))
        }

        if let nonRotatedConicIntent = classifyNonRotatedQuadraticConicIntent(equationExpr) {
            return GraphClassificationResult(intent: nonRotatedConicIntent)
        }

        let both = variableNames(in: equationExpr)
        if both.contains("x") && both.contains("y") {
            return GraphClassificationResult(intent: .implicit(relation: equationExpr))
        }

        return GraphClassificationResult(
            intent: .unknown(equationExpr),
            diagnostics: [diag(.unsupportedRelation, "当前方程形式暂不支持自动分类")]
        )
    }

    private func classifyRelation(_ expr: Expr) -> GraphClassificationResult {
        if let namedPoint = classifyNamedPointRelation(expr) {
            return GraphClassificationResult(intent: namedPoint)
        }
        if case .relation(let left, let relation, let right) = expr,
           relation == .equal,
           let circleIntent = classifyOriginCircleIntent(left: left, right: right) {
            return GraphClassificationResult(intent: circleIntent)
        }
        if case .relation(let left, let relation, let right) = expr,
           relation == .equal,
           let translatedCircleIntent = classifyTranslatedCircleIntent(left: left, right: right) {
            return GraphClassificationResult(intent: translatedCircleIntent)
        }
        if case .relation(let left, let relation, let right) = expr,
           relation == .equal,
           let conicIntent = classifyStandardOriginConicIntent(left: left, right: right, source: expr) {
            return GraphClassificationResult(intent: conicIntent)
        }
        if case .relation(let left, let relation, let right) = expr,
           relation == .equal,
           let translatedConicIntent = classifyStandardTranslatedConicIntent(left: left, right: right, source: expr) {
            return GraphClassificationResult(intent: translatedConicIntent)
        }
        if let nonRotatedConicIntent = classifyNonRotatedQuadraticConicIntent(expr) {
            return GraphClassificationResult(intent: nonRotatedConicIntent)
        }

        if let polarRadius = polarRadiusFromRelation(expr) {
            return classifyPolarRadius(radiusExpr: polarRadius, source: expr)
        }

        let vars = variableNames(in: expr)
        if vars.contains("x") && vars.contains("y") {
            return GraphClassificationResult(intent: .implicit(relation: expr))
        }
        if vars.contains("x") || vars.contains("y") {
            return GraphClassificationResult(intent: .implicit(relation: expr))
        }
        return GraphClassificationResult(
            intent: .unknown(expr),
            diagnostics: [diag(.unsupportedRelation, "关系表达式缺少可绘制变量")]
        )
    }

    private func classifyNamedPointEquation(left: Expr, right: Expr) -> GraphIntent? {
        classifyNamedPoint(left: left, right: right)
    }

    private func classifyNamedPointRelation(_ expr: Expr) -> GraphIntent? {
        guard case .relation(let left, let relation, let right) = expr, relation == .equal else {
            return nil
        }
        return classifyNamedPoint(left: left, right: right)
    }

    private func classifyNamedPoint(left: Expr, right: Expr) -> GraphIntent? {
        guard case .symbol(let symbol) = left else { return nil }
        guard !["x", "y", "r"].contains(symbol.name) else { return nil }
        guard case .tuple(let values) = right, values.count == 2 else { return nil }
        return .point(x: values[0], y: values[1])
    }

    private func classifyTuple(_ values: [Expr], source: Expr) -> GraphClassificationResult {
        if let parametric = classifyXYEquationTuple(values, source: source) {
            return parametric
        }
        if let polar = classifyPolarTuple(values, source: source) {
            return polar
        }

        guard values.count == 2 else {
            return GraphClassificationResult(
                intent: .unknown(source),
                diagnostics: [diag(.unsupportedParametricForm, "仅支持二维 tuple 作为点或参数曲线")]
            )
        }
        return GraphClassificationResult(intent: .point(x: values[0], y: values[1]))
    }

    private func classifyPolarTuple(_ values: [Expr], source: Expr) -> GraphClassificationResult? {
        var radiusExpr: Expr?
        var remainder: [Expr] = []

        for value in values {
            if radiusExpr == nil, let radius = polarRadiusFromEquationLike(value) {
                radiusExpr = radius
                continue
            }
            remainder.append(value)
        }
        guard let radiusExpr else { return nil }
        return classifyPolarRadius(radiusExpr: radiusExpr, source: source, conditions: remainder)
    }

    private func classifyPiecewise(_ branches: [PiecewiseBranch]) -> GraphClassificationResult {
        var diagnostics: [GraphDiagnostic] = []
        var intents: [GraphIntentBranch] = []

        for branch in branches {
            let result = classify(branch.value)
            intents.append(GraphIntentBranch(condition: branch.condition, intent: result.intent))
            diagnostics.append(contentsOf: result.diagnostics)
            if case .unknown = result.intent {
                diagnostics.append(diag(.unsupportedPiecewiseBranch, "分段分支无法识别为可绘制意图", severity: .warning))
            }
        }
        return GraphClassificationResult(intent: .piecewise(intents), diagnostics: diagnostics)
    }

    private func classifyFunction(_ function: MathFunction, arguments: [Expr], source: Expr) -> GraphClassificationResult {
        if case .custom(let name) = function, name.lowercased() == "circle" {
            guard arguments.count == 2 else {
                return GraphClassificationResult(
                    intent: .unknown(source),
                    diagnostics: [diag(.unsupportedExpression, "circle 需要两个参数：circle((cx,cy), r)")]
                )
            }
            let center = arguments[0]
            let radius = arguments[1]
            guard case .tuple(let centerItems) = center, centerItems.count == 2 else {
                return GraphClassificationResult(
                    intent: .unknown(source),
                    diagnostics: [diag(.unsupportedExpression, "circle 第一个参数需要是二维 tuple 圆心")]
                )
            }
            return GraphClassificationResult(intent: .circle(center: center, radius: radius))
        }

        return GraphClassificationResult(
            intent: .explicitY(expression: source, variable: Symbol(name: "x", role: .variable))
        )
    }

    private func isSymbol(_ expr: Expr, named name: String) -> Bool {
        guard case .symbol(let symbol) = expr else { return false }
        return symbol.name == name
    }

    private func classifyXYEquationTuple(_ values: [Expr], source: Expr) -> GraphClassificationResult? {
        guard values.count >= 2 else { return nil }

        var xExpr: Expr?
        var yExpr: Expr?
        var remainder: [Expr] = []

        for value in values {
            if let axis = axisEquation(value) {
                if axis.axis == "x", xExpr == nil {
                    xExpr = axis.rhs
                    continue
                }
                if axis.axis == "y", yExpr == nil {
                    yExpr = axis.rhs
                    continue
                }
            }
            remainder.append(value)
        }
        guard let xExpr, let yExpr else { return nil }
        guard !containsEmbeddedCondition(xExpr), !containsEmbeddedCondition(yExpr) else {
            return GraphClassificationResult(
                intent: .unknown(source),
                diagnostics: [diag(.unsupportedExpression, "参数方程范围必须作为独立同级项，而不能嵌入 x/y 表达式")]
            )
        }

        let parameterCandidates = variableNames(in: xExpr)
            .union(variableNames(in: yExpr))
            .subtracting(["x", "y"])
            .subtracting(parameterSymbolNames)
        let rangeVariableCandidates = parameterNames(in: remainder)
        let rangeVariable = rangeVariableCandidates.count == 1 ? rangeVariableCandidates.first : nil
        let parameter: String
        if let rangeVariable {
            if parameterSymbolNames.contains(rangeVariable) {
                return GraphClassificationResult(
                    intent: .unknown(source),
                    diagnostics: [diag(.ambiguousVariables, "定义域变量与滑动条参数冲突: \(rangeVariable)")]
                )
            }
            if parameterCandidates.isEmpty || parameterCandidates.contains(rangeVariable) {
                parameter = rangeVariable
            } else {
                return GraphClassificationResult(
                    intent: .unknown(source),
                    diagnostics: [diag(.ambiguousVariables, "参数变量与定义域变量不一致")]
                )
            }
        } else if parameterCandidates.count == 1, let single = parameterCandidates.first {
            parameter = single
        } else if parameterCandidates.isEmpty {
            parameter = defaultParameterName(usedNames: variableNames(in: source))
        } else {
            return GraphClassificationResult(
                intent: .unknown(source),
                diagnostics: [diag(.ambiguousVariables, "参数变量不唯一: \(parameterCandidates.sorted().joined(separator: ", "))")]
            )
        }

        let explicitRange = extractParameterRange(for: parameter, in: remainder)
        let inferredRange = inferRangeFromPiecewiseExpressions(parameter: parameter, expressions: [xExpr, yExpr])
        let range = explicitRange ?? inferredRange
        return GraphClassificationResult(
            intent: .parametric2D(
                x: xExpr,
                y: yExpr,
                parameter: Symbol(name: parameter, role: .parameter),
                range: range
            )
        )
    }

    private func defaultParameterName(usedNames: Set<String>) -> String {
        let ordered = ["t", "u", "v", "s"]
        for candidate in ordered where !usedNames.contains(candidate) {
            return candidate
        }
        return "t"
    }

    private func parameterNames(in conditions: [Expr]) -> Set<String> {
        var names: Set<String> = []
        for condition in conditions {
            switch condition {
            case .chainedRelation(let expressions, _):
                for expr in expressions {
                    guard case .symbol(let symbol) = expr else { continue }
                    if symbol.name == "x" || symbol.name == "y" { continue }
                    names.insert(symbol.name)
                }
            case .relation(let left, let relation, let right):
                switch relation {
                case .less, .lessOrEqual, .greater, .greaterOrEqual:
                    if case .symbol(let symbol) = left, symbol.name != "x", symbol.name != "y" {
                        names.insert(symbol.name)
                    }
                    if case .symbol(let symbol) = right, symbol.name != "x", symbol.name != "y" {
                        names.insert(symbol.name)
                    }
                default:
                    continue
                }
            default:
                continue
            }
        }
        return names
    }

    private func axisEquation(_ expr: Expr) -> (axis: String, rhs: Expr)? {
        switch expr {
        case .equation(let left, let right):
            guard case .symbol(let symbol) = left else { return nil }
            guard symbol.name == "x" || symbol.name == "y" else { return nil }
            return (axis: symbol.name, rhs: right)
        case .relation(let left, let relation, let right):
            guard relation == .equal else { return nil }
            guard case .symbol(let symbol) = left else { return nil }
            guard symbol.name == "x" || symbol.name == "y" else { return nil }
            return (axis: symbol.name, rhs: right)
        default:
            return nil
        }
    }

    private func polarRadiusFromRelation(_ expr: Expr) -> Expr? {
        guard case .relation(let left, let relation, let right) = expr else { return nil }
        guard relation == .equal else { return nil }
        guard isSymbol(left, named: "r") else { return nil }
        return right
    }

    private func polarRadiusFromEquationLike(_ expr: Expr) -> Expr? {
        switch expr {
        case .equation(let left, let right):
            return isSymbol(left, named: "r") ? right : nil
        case .relation(let left, let relation, let right):
            guard relation == .equal, isSymbol(left, named: "r") else { return nil }
            return right
        default:
            return nil
        }
    }

    private func classifyPolarRadius(
        radiusExpr: Expr,
        source: Expr,
        conditions: [Expr] = []
    ) -> GraphClassificationResult {
        let candidates = variableNames(in: radiusExpr).subtracting(["r"])
        if candidates.isEmpty {
            return GraphClassificationResult(
                intent: .unknown(source),
                diagnostics: [diag(.missingVariable, "极坐标表达式缺少角变量")]
            )
        }

        let angleName: String
        if candidates.count == 1, let single = candidates.first {
            angleName = single
        } else {
            return GraphClassificationResult(
                intent: .unknown(source),
                diagnostics: [diag(.ambiguousVariables, "极坐标角变量不唯一: \(candidates.sorted().joined(separator: ", "))")]
            )
        }

        let range = extractParameterRange(for: angleName, in: conditions)
        return GraphClassificationResult(
            intent: .polar(
                radius: radiusExpr,
                angle: Symbol(name: angleName, role: .parameter),
                range: range
            )
        )
    }

    private func extractParameterRange(for parameter: String, in conditions: [Expr]) -> ParameterRange? {
        for condition in conditions {
            if let range = extractRangeFromChainedRelation(condition, parameter: parameter) {
                return range
            }
        }

        var lowerBound: Expr?
        var upperBound: Expr?
        for condition in conditions {
            if let pair = extractBoundsFromRelation(condition, parameter: parameter) {
                if let lower = pair.lower {
                    lowerBound = lower
                }
                if let upper = pair.upper {
                    upperBound = upper
                }
            }
        }
        if lowerBound != nil || upperBound != nil {
            return ParameterRange(lower: lowerBound, upper: upperBound)
        }
        return nil
    }

    private func inferRangeFromPiecewiseExpressions(
        parameter: String,
        expressions: [Expr]
    ) -> ParameterRange? {
        var conditions: [Expr] = []
        for expression in expressions {
            collectPiecewiseConditions(from: expression, into: &conditions)
        }
        guard !conditions.isEmpty else { return nil }

        let evaluator = ExprEvaluator()
        var minLower: Double?
        var maxUpper: Double?
        var hasAnyBound = false

        for condition in conditions {
            if let chained = extractRangeFromChainedRelation(condition, parameter: parameter) {
                if let lowerExpr = chained.lower,
                   case .value(let lowerValue) = evaluator.evaluate(lowerExpr),
                   lowerValue.isFinite {
                    minLower = min(minLower ?? lowerValue, lowerValue)
                    hasAnyBound = true
                }
                if let upperExpr = chained.upper,
                   case .value(let upperValue) = evaluator.evaluate(upperExpr),
                   upperValue.isFinite {
                    maxUpper = max(maxUpper ?? upperValue, upperValue)
                    hasAnyBound = true
                }
                continue
            }

            guard let direct = extractBoundsFromRelation(condition, parameter: parameter) else { continue }
            if let lowerExpr = direct.lower,
               case .value(let lowerValue) = evaluator.evaluate(lowerExpr),
               lowerValue.isFinite {
                minLower = min(minLower ?? lowerValue, lowerValue)
                hasAnyBound = true
            }
            if let upperExpr = direct.upper,
               case .value(let upperValue) = evaluator.evaluate(upperExpr),
               upperValue.isFinite {
                maxUpper = max(maxUpper ?? upperValue, upperValue)
                hasAnyBound = true
            }
        }

        guard hasAnyBound else { return nil }
        let lowerExpr = minLower.map(Expr.real)
        let upperExpr = maxUpper.map(Expr.real)
        if let lower = minLower, let upper = maxUpper, !(lower < upper) {
            return nil
        }
        return ParameterRange(lower: lowerExpr, upper: upperExpr)
    }

    private func collectPiecewiseConditions(from expr: Expr, into conditions: inout [Expr]) {
        switch expr {
        case .piecewise(let branches, let otherwise):
            for branch in branches {
                conditions.append(branch.condition)
                collectPiecewiseConditions(from: branch.value, into: &conditions)
            }
            if let otherwise {
                collectPiecewiseConditions(from: otherwise, into: &conditions)
            }
        case .add(let values), .multiply(let values), .tuple(let values), .vector(let values):
            for value in values {
                collectPiecewiseConditions(from: value, into: &conditions)
            }
        case .power(let base, let exponent):
            collectPiecewiseConditions(from: base, into: &conditions)
            collectPiecewiseConditions(from: exponent, into: &conditions)
        case .divide(let numerator, let denominator):
            collectPiecewiseConditions(from: numerator, into: &conditions)
            collectPiecewiseConditions(from: denominator, into: &conditions)
        case .negate(let value):
            collectPiecewiseConditions(from: value, into: &conditions)
        case .function(_, let arguments):
            for argument in arguments {
                collectPiecewiseConditions(from: argument, into: &conditions)
            }
        default:
            break
        }
    }

    private func extractRangeFromChainedRelation(_ expr: Expr, parameter: String) -> ParameterRange? {
        guard case .chainedRelation(let expressions, let relations) = expr else { return nil }
        guard expressions.count == 3, relations.count == 2 else { return nil }
        guard case .symbol(let symbol) = expressions[1], symbol.name == parameter else { return nil }

        let first = relations[0]
        let second = relations[1]
        switch (first, second) {
        case (.less, .less), (.less, .lessOrEqual), (.lessOrEqual, .less), (.lessOrEqual, .lessOrEqual):
            return ParameterRange(lower: expressions[0], upper: expressions[2])
        case (.greater, .greater), (.greater, .greaterOrEqual), (.greaterOrEqual, .greater), (.greaterOrEqual, .greaterOrEqual):
            return ParameterRange(lower: expressions[2], upper: expressions[0])
        default:
            return nil
        }
    }

    private func extractBoundsFromRelation(_ expr: Expr, parameter: String) -> (lower: Expr?, upper: Expr?)? {
        guard case .relation(let left, let relation, let right) = expr else { return nil }

        if case .symbol(let symbol) = left, symbol.name == parameter {
            switch relation {
            case .greater, .greaterOrEqual:
                return (lower: right, upper: nil)
            case .less, .lessOrEqual:
                return (lower: nil, upper: right)
            default:
                return nil
            }
        }

        if case .symbol(let symbol) = right, symbol.name == parameter {
            switch relation {
            case .greater, .greaterOrEqual:
                return (lower: nil, upper: left)
            case .less, .lessOrEqual:
                return (lower: left, upper: nil)
            default:
                return nil
            }
        }
        return nil
    }

    private func variableNames(in expr: Expr) -> Set<String> {
        var result: Set<String> = []

        func collect(_ value: Expr) {
            switch value {
            case .symbol(let symbol):
                switch symbol.role {
                case .variable, .parameter, .unknown:
                    result.insert(symbol.name)
                case .function, .constant, .objectName, .unit:
                    break
                }
            case .add(let terms):
                terms.forEach(collect)
            case .multiply(let factors):
                factors.forEach(collect)
            case .power(let base, let exponent):
                collect(base); collect(exponent)
            case .negate(let inner):
                collect(inner)
            case .divide(let n, let d):
                collect(n); collect(d)
            case .function(_, let arguments):
                arguments.forEach(collect)
            case .equation(let left, let right):
                collect(left); collect(right)
            case .relation(let left, _, let right):
                collect(left); collect(right)
            case .chainedRelation(let expressions, _):
                expressions.forEach(collect)
            case .piecewise(let branches, let otherwise):
                branches.forEach {
                    collect($0.value)
                    collect($0.condition)
                }
                if let otherwise { collect(otherwise) }
            case .tuple(let values):
                values.forEach(collect)
            case .vector(let values):
                values.forEach(collect)
            case .matrix(let matrix):
                matrix.rows.flatMap { $0 }.forEach(collect)
            case .assignment(let target, let value):
                collect(target); collect(value)
            case .functionDefinition(_, let parameters, let body):
                var bodyVars: Set<String> = []
                collect(body)
                bodyVars = result
                for parameter in parameters {
                    bodyVars.remove(parameter.name)
                }
                result = bodyVars
            case .integer, .rational, .decimal, .real, .constant, .unknown:
                break
            }
        }

        collect(expr)
        return result
    }

    private func containsEmbeddedCondition(_ expr: Expr) -> Bool {
        switch expr {
        case .relation, .equation, .chainedRelation:
            return true
        case .add(let values), .multiply(let values), .tuple(let values):
            return values.contains(where: containsEmbeddedCondition)
        case .power(let base, let exponent):
            return containsEmbeddedCondition(base) || containsEmbeddedCondition(exponent)
        case .negate(let value):
            return containsEmbeddedCondition(value)
        case .divide(let numerator, let denominator):
            return containsEmbeddedCondition(numerator) || containsEmbeddedCondition(denominator)
        case .function(_, let arguments):
            return arguments.contains(where: containsEmbeddedCondition)
        case .piecewise(let branches, let otherwise):
            if branches.contains(where: { containsEmbeddedCondition($0.value) }) {
                return true
            }
            if let otherwise {
                return containsEmbeddedCondition(otherwise)
            }
            return false
        default:
            return false
        }
    }

    private func diag(
        _ code: GraphDiagnosticCode,
        _ message: String,
        severity: GraphDiagnosticSeverity = .warning
    ) -> GraphDiagnostic {
        GraphDiagnostic(severity: severity, code: code, message: message)
    }

    private func classifyOriginCircleIntent(left: Expr, right: Expr) -> GraphIntent? {
        if isOriginCircleLHS(left), let radius = radiusExpressionIfPositive(from: right) {
            return .circle(center: .tuple([.integer(0), .integer(0)]), radius: radius)
        }
        if isOriginCircleLHS(right), let radius = radiusExpressionIfPositive(from: left) {
            return .circle(center: .tuple([.integer(0), .integer(0)]), radius: radius)
        }
        return nil
    }

    private func classifyTranslatedCircleIntent(left: Expr, right: Expr) -> GraphIntent? {
        if let center = translatedCircleCenterIfValid(left), let radius = radiusExpressionIfPositive(from: right) {
            return .circle(center: center, radius: radius)
        }
        if let center = translatedCircleCenterIfValid(right), let radius = radiusExpressionIfPositive(from: left) {
            return .circle(center: center, radius: radius)
        }
        return nil
    }

    private func translatedCircleCenterIfValid(_ expr: Expr) -> Expr? {
        let terms: [Expr]
        if case .add(let values) = expr {
            terms = values
        } else {
            terms = [expr]
        }
        guard terms.count == 2 else { return nil }

        var xCenter: Expr?
        var yCenter: Expr?
        for term in terms {
            guard let parsed = parseShiftedSquareTerm(term) else { return nil }
            switch parsed.axis {
            case "x":
                guard xCenter == nil else { return nil }
                xCenter = parsed.center
            case "y":
                guard yCenter == nil else { return nil }
                yCenter = parsed.center
            default:
                return nil
            }
        }
        guard let xCenter, let yCenter else { return nil }
        let evaluator = ExprEvaluator()
        guard case .value(let cx) = evaluator.evaluate(xCenter), cx.isFinite else { return nil }
        guard case .value(let cy) = evaluator.evaluate(yCenter), cy.isFinite else { return nil }
        return .tuple([xCenter, yCenter])
    }

    private func parseShiftedSquareTerm(_ expr: Expr) -> (axis: String, center: Expr)? {
        guard case .power(let base, let exponent) = expr else { return nil }
        guard integerValueIfExact(exponent) == 2 else { return nil }
        guard let parsed = parseAxisWithOffset(base) else { return nil }
        let center = simplifier.simplify(.negate(parsed.offset))
        return (axis: parsed.axis, center: center)
    }

    private func parseAxisWithOffset(_ expr: Expr) -> (axis: String, offset: Expr)? {
        if case .symbol(let symbol) = expr, symbol.name == "x" || symbol.name == "y" {
            return (axis: symbol.name, offset: .integer(0))
        }

        guard case .add(let terms) = expr, terms.count == 2 else { return nil }
        var axis: String?
        var offset: Expr?

        for term in terms {
            if case .symbol(let symbol) = term, symbol.name == "x" || symbol.name == "y" {
                guard axis == nil else { return nil }
                axis = symbol.name
                continue
            }
            guard offset == nil else { return nil }
            offset = term
        }

        guard let axis, let offset else { return nil }
        return (axis: axis, offset: offset)
    }

    private func isOriginCircleLHS(_ expr: Expr) -> Bool {
        let terms: [Expr]
        if case .add(let values) = expr {
            terms = values
        } else {
            terms = [expr]
        }
        guard terms.count == 2 else { return false }
        let hasX2 = terms.contains(where: { isPowerOfSymbol($0, name: "x", exponent: 2) })
        let hasY2 = terms.contains(where: { isPowerOfSymbol($0, name: "y", exponent: 2) })
        return hasX2 && hasY2
    }

    private func isPowerOfSymbol(_ expr: Expr, name: String, exponent: Int) -> Bool {
        guard case .power(let base, let exp) = expr else { return false }
        guard case .symbol(let symbol) = base, symbol.name == name else { return false }
        return integerValueIfExact(exp) == exponent
    }

    private func integerValueIfExact(_ expr: Expr) -> Int? {
        switch expr {
        case .integer(let value):
            return value
        case .rational(let numerator, let denominator):
            guard denominator != 0, numerator % denominator == 0 else { return nil }
            return numerator / denominator
        case .real(let value):
            let rounded = value.rounded()
            guard abs(value - rounded) <= 1e-12 else { return nil }
            return Int(rounded)
        case .decimal(let text):
            guard let value = Double(text) else { return nil }
            let rounded = value.rounded()
            guard abs(value - rounded) <= 1e-12 else { return nil }
            return Int(rounded)
        default:
            return nil
        }
    }

    private func radiusExpressionIfPositive(from expr: Expr) -> Expr? {
        let evaluation = ExprEvaluator().evaluate(expr)
        guard case .value(let c) = evaluation, c.isFinite, c > 0 else { return nil }
        if integerValueIfExact(expr) == 1 {
            return .integer(1)
        }
        return .function(.sqrt, arguments: [expr])
    }

    private func classifyStandardOriginConicIntent(left: Expr, right: Expr, source: Expr) -> GraphIntent? {
        if let lhs = parseStandardOriginConicLHS(left), isExactlyOne(right) {
            return makeConicIntent(from: lhs, source: source)
        }
        if let rhs = parseStandardOriginConicLHS(right), isExactlyOne(left) {
            return makeConicIntent(from: rhs, source: source)
        }
        return nil
    }

    private func classifyStandardTranslatedConicIntent(left: Expr, right: Expr, source: Expr) -> GraphIntent? {
        if let lhs = parseStandardTranslatedConicLHS(left), isExactlyOne(right) {
            return makeTranslatedConicIntent(from: lhs, source: source)
        }
        if let rhs = parseStandardTranslatedConicLHS(right), isExactlyOne(left) {
            return makeTranslatedConicIntent(from: rhs, source: source)
        }
        return nil
    }

    private func isExactlyOne(_ expr: Expr) -> Bool {
        let evaluation = ExprEvaluator().evaluate(expr)
        guard case .value(let v) = evaluation else { return false }
        return abs(v - 1.0) <= 1e-12
    }

    private struct StandardOriginConicLHS {
        let xSign: Int
        let xDenominator: Expr
        let ySign: Int
        let yDenominator: Expr
    }

    private struct StandardTranslatedConicLHS {
        let xSign: Int
        let xDenominator: Expr
        let ySign: Int
        let yDenominator: Expr
        let centerX: Expr
        let centerY: Expr
    }

    private func parseStandardOriginConicLHS(_ expr: Expr) -> StandardOriginConicLHS? {
        let terms = signedTerms(in: expr)
        guard terms.count == 2 else { return nil }

        var xPart: (sign: Int, denominator: Expr)?
        var yPart: (sign: Int, denominator: Expr)?

        for item in terms {
            guard let quadratic = parseAxisSquaredOverDenominator(item.term) else { return nil }
            if quadratic.axis == "x" {
                guard xPart == nil else { return nil }
                xPart = (item.sign, quadratic.denominator)
            } else if quadratic.axis == "y" {
                guard yPart == nil else { return nil }
                yPart = (item.sign, quadratic.denominator)
            } else {
                return nil
            }
        }

        guard let xPart, let yPart else { return nil }
        guard denominatorIsPositiveNumeric(xPart.denominator), denominatorIsPositiveNumeric(yPart.denominator) else { return nil }

        return StandardOriginConicLHS(
            xSign: xPart.sign,
            xDenominator: xPart.denominator,
            ySign: yPart.sign,
            yDenominator: yPart.denominator
        )
    }

    private func parseStandardTranslatedConicLHS(_ expr: Expr) -> StandardTranslatedConicLHS? {
        let terms = signedTerms(in: expr)
        guard terms.count == 2 else { return nil }

        var xPart: (sign: Int, denominator: Expr, center: Expr)?
        var yPart: (sign: Int, denominator: Expr, center: Expr)?

        for item in terms {
            guard let quadratic = parseShiftedAxisSquaredOverDenominator(item.term) else { return nil }
            if quadratic.axis == "x" {
                guard xPart == nil else { return nil }
                xPart = (item.sign, quadratic.denominator, quadratic.center)
            } else if quadratic.axis == "y" {
                guard yPart == nil else { return nil }
                yPart = (item.sign, quadratic.denominator, quadratic.center)
            } else {
                return nil
            }
        }

        guard let xPart, let yPart else { return nil }
        guard denominatorIsPositiveNumeric(xPart.denominator), denominatorIsPositiveNumeric(yPart.denominator) else { return nil }

        return StandardTranslatedConicLHS(
            xSign: xPart.sign,
            xDenominator: xPart.denominator,
            ySign: yPart.sign,
            yDenominator: yPart.denominator,
            centerX: xPart.center,
            centerY: yPart.center
        )
    }

    private func signedTerms(in expr: Expr) -> [(sign: Int, term: Expr)] {
        let baseTerms: [Expr]
        if case .add(let values) = expr {
            baseTerms = values
        } else {
            baseTerms = [expr]
        }
        return baseTerms.map { term in
            if case .negate(let inner) = term {
                return (sign: -1, term: inner)
            }
            if case .multiply(let factors) = term {
                var mutable = factors
                if let idx = mutable.firstIndex(where: { integerValueIfExact($0) == -1 }) {
                    mutable.remove(at: idx)
                    if mutable.isEmpty {
                        return (sign: -1, term: .integer(1))
                    }
                    if mutable.count == 1 {
                        return (sign: -1, term: mutable[0])
                    }
                    return (sign: -1, term: .multiply(mutable))
                }
            }
            return (sign: 1, term: term)
        }
    }

    private func parseAxisSquaredOverDenominator(_ expr: Expr) -> (axis: String, denominator: Expr)? {
        if case .divide(let numerator, let denominator) = expr,
           let axis = axisNameIfSquared(numerator) {
            return (axis: axis, denominator: denominator)
        }

        if case .multiply(let factors) = expr {
            var axis: String?
            var denominator: Expr?
            var unresolved: [Expr] = []

            for factor in factors {
                if axis == nil, let parsedAxis = axisNameIfSquared(factor) {
                    axis = parsedAxis
                    continue
                }
                if denominator == nil,
                   case .power(let base, let exponent) = factor,
                   integerValueIfExact(exponent) == -1 {
                    denominator = base
                    continue
                }
                unresolved.append(factor)
            }
            guard unresolved.isEmpty, let axis, let denominator else { return nil }
            return (axis: axis, denominator: denominator)
        }

        return nil
    }

    private func parseShiftedAxisSquaredOverDenominator(_ expr: Expr) -> (axis: String, denominator: Expr, center: Expr)? {
        if case .divide(let numerator, let denominator) = expr,
           let shifted = parseShiftedSquareTerm(numerator) {
            return (axis: shifted.axis, denominator: denominator, center: shifted.center)
        }

        if case .multiply(let factors) = expr {
            var shifted: (axis: String, center: Expr)?
            var denominator: Expr?
            var unresolved: [Expr] = []

            for factor in factors {
                if shifted == nil, let parsed = parseShiftedSquareTerm(factor) {
                    shifted = (axis: parsed.axis, center: parsed.center)
                    continue
                }
                if denominator == nil,
                   case .power(let base, let exponent) = factor,
                   integerValueIfExact(exponent) == -1 {
                    denominator = base
                    continue
                }
                unresolved.append(factor)
            }

            guard unresolved.isEmpty, let shifted, let denominator else { return nil }
            return (axis: shifted.axis, denominator: denominator, center: shifted.center)
        }

        return nil
    }

    private func axisNameIfSquared(_ expr: Expr) -> String? {
        guard case .power(let base, let exponent) = expr else { return nil }
        guard integerValueIfExact(exponent) == 2 else { return nil }
        guard case .symbol(let symbol) = base else { return nil }
        guard symbol.name == "x" || symbol.name == "y" else { return nil }
        return symbol.name
    }

    private func denominatorIsPositiveNumeric(_ expr: Expr) -> Bool {
        let evaluation = ExprEvaluator().evaluate(expr)
        guard case .value(let value) = evaluation else { return false }
        return value.isFinite && value > 0
    }

    private func makeConicIntent(from lhs: StandardOriginConicLHS, source: Expr) -> GraphIntent? {
        let aExpr: Expr = .function(.sqrt, arguments: [lhs.xDenominator])
        let bExpr: Expr = .function(.sqrt, arguments: [lhs.yDenominator])

        let canonicalForm: ConicCanonicalForm
        let kind: ConicKind
        switch (lhs.xSign, lhs.ySign) {
        case (1, 1):
            canonicalForm = .originEllipse(a: aExpr, b: bExpr)
            kind = .ellipse
        case (1, -1):
            canonicalForm = .originHyperbolaX(a: aExpr, b: bExpr)
            kind = .hyperbola
        case (-1, 1):
            canonicalForm = .originHyperbolaY(a: aExpr, b: bExpr)
            kind = .hyperbola
        default:
            return nil
        }

        return .conic(
            ConicInfo(
                kind: kind,
                source: source,
                canonicalForm: canonicalForm,
                orientation: .axisAligned
            )
        )
    }

    private func makeTranslatedConicIntent(from lhs: StandardTranslatedConicLHS, source: Expr) -> GraphIntent? {
        let center = Expr.tuple([lhs.centerX, lhs.centerY])
        let aExpr: Expr = .function(.sqrt, arguments: [lhs.xDenominator])
        let bExpr: Expr = .function(.sqrt, arguments: [lhs.yDenominator])

        let canonicalForm: ConicCanonicalForm
        let kind: ConicKind
        switch (lhs.xSign, lhs.ySign) {
        case (1, 1):
            canonicalForm = .translatedEllipse(center: center, a: aExpr, b: bExpr)
            kind = .ellipse
        case (1, -1):
            canonicalForm = .translatedHyperbolaX(center: center, a: aExpr, b: bExpr)
            kind = .hyperbola
        case (-1, 1):
            canonicalForm = .translatedHyperbolaY(center: center, a: aExpr, b: bExpr)
            kind = .hyperbola
        default:
            return nil
        }

        return .conic(
            ConicInfo(
                kind: kind,
                source: source,
                canonicalForm: canonicalForm,
                orientation: .axisAligned
            )
        )
    }

    private func classifyNonRotatedQuadraticConicIntent(_ source: Expr) -> GraphIntent? {
        let zeroForm = quadraticZeroForm(from: source)
        guard let form = extractQuadraticFormForClassification(zeroForm) else {
            return nil
        }

        let epsilon = 1e-9
        let a = form.xx
        let b = form.xy
        let c = form.yy
        let d = form.x
        let e = form.y
        let f = form.constant

        if abs(b) > epsilon {
            return classifyRotatedQuadraticConicIntent(
                source: source,
                a: a,
                b: b,
                c: c,
                d: d,
                e: e,
                f: f,
                epsilon: epsilon
            )
        }

        // Non-rotated parabola path (4D): exactly one quadratic axis survives.
        if abs(a) > epsilon, abs(c) <= epsilon {
            guard abs(e) > epsilon else { return nil }
            let h = -d / (2.0 * a)
            let fPrime = f - (d * d) / (4.0 * a)
            let coefficient = -a / e
            let k = -fPrime / e
            return .conic(
                ConicInfo(
                    kind: .parabola,
                    source: source,
                    canonicalForm: .translatedParabolaY(
                        vertex: .tuple([.real(h), .real(k)]),
                        coefficient: .real(coefficient)
                    ),
                    orientation: .axisAligned
                )
            )
        }

        if abs(c) > epsilon, abs(a) <= epsilon {
            guard abs(d) > epsilon else { return nil }
            let k = -e / (2.0 * c)
            let fPrime = f - (e * e) / (4.0 * c)
            let coefficient = -c / d
            let h = -fPrime / d
            return .conic(
                ConicInfo(
                    kind: .parabola,
                    source: source,
                    canonicalForm: .translatedParabolaX(
                        vertex: .tuple([.real(h), .real(k)]),
                        coefficient: .real(coefficient)
                    ),
                    orientation: .axisAligned
                )
            )
        }

        guard abs(a) > epsilon, abs(c) > epsilon else { return nil }

        let h = -d / (2.0 * a)
        let k = -e / (2.0 * c)
        let r = -f + (d * d) / (4.0 * a) + (e * e) / (4.0 * c)

        if a * c > 0 {
            let posA: Double
            let posC: Double
            let posR: Double
            if a > 0 && c > 0 {
                posA = a; posC = c; posR = r
            } else if a < 0 && c < 0 {
                posA = -a; posC = -c; posR = -r
            } else {
                return nil
            }

            guard posR > epsilon else { return nil }
            let aSquared = posR / posA
            let bSquared = posR / posC
            guard aSquared > epsilon, bSquared > epsilon else { return nil }

            let center = Expr.tuple([.real(h), .real(k)])
            if abs(aSquared - bSquared) <= epsilon {
                return .circle(
                    center: center,
                    radius: .function(.sqrt, arguments: [.real(aSquared)])
                )
            }

            return .conic(
                ConicInfo(
                    kind: .ellipse,
                    source: source,
                    canonicalForm: .translatedEllipse(
                        center: center,
                        a: .function(.sqrt, arguments: [.real(aSquared)]),
                        b: .function(.sqrt, arguments: [.real(bSquared)])
                    ),
                    orientation: .axisAligned
                )
            )
        }

        if a * c < 0 {
            let ratioXA = r / a
            let ratioYC = r / c
            let center = Expr.tuple([.real(h), .real(k)])

            if ratioXA > epsilon {
                let aSquared = ratioXA
                let bSquared = abs(ratioYC)
                guard bSquared > epsilon else { return nil }
                return .conic(
                    ConicInfo(
                        kind: .hyperbola,
                        source: source,
                        canonicalForm: .translatedHyperbolaX(
                            center: center,
                            a: .function(.sqrt, arguments: [.real(aSquared)]),
                            b: .function(.sqrt, arguments: [.real(bSquared)])
                        ),
                        orientation: .axisAligned
                    )
                )
            }

            if ratioYC > epsilon {
                let bSquared = ratioYC
                let aSquared = abs(ratioXA)
                guard aSquared > epsilon else { return nil }
                return .conic(
                    ConicInfo(
                        kind: .hyperbola,
                        source: source,
                        canonicalForm: .translatedHyperbolaY(
                            center: center,
                            a: .function(.sqrt, arguments: [.real(aSquared)]),
                            b: .function(.sqrt, arguments: [.real(bSquared)])
                        ),
                        orientation: .axisAligned
                    )
                )
            }
        }

        return nil
    }

    private func extractQuadraticFormForClassification(_ expr: Expr) -> QuadraticForm2D? {
        let extractor = QuadraticFormExtractor()

        if case .success(let strictForm) = extractor.extract(expr, options: .strict) {
            return strictForm
        }

        if case .success(let expandedForm) = extractor.extract(expr, options: .expanded2D) {
            return expandedForm
        }

        return nil
    }

    private func classifyRotatedQuadraticConicIntent(
        source: Expr,
        a: Double,
        b: Double,
        c: Double,
        d: Double,
        e: Double,
        f: Double,
        epsilon: Double
    ) -> GraphIntent? {
        // Solve center for non-parabolic, non-degenerate conics:
        // [2A B; B 2C] [h k]^T = -[D E]^T
        let determinant = 4.0 * a * c - b * b
        guard abs(determinant) > epsilon else { return nil }

        let h = (b * e - 2.0 * c * d) / determinant
        let k = (b * d - 2.0 * a * e) / determinant

        // Evaluate quadratic at center after translation.
        let fCenter = a * h * h + b * h * k + c * k * k + d * h + e * k + f
        let r = -fCenter

        // Eigenvalues of Q = [[A, B/2], [B/2, C]] are local quadratic coefficients.
        let halfTrace = 0.5 * (a + c)
        let halfDiff = 0.5 * (a - c)
        let offDiag = 0.5 * b
        let delta = Foundation.sqrt(halfDiff * halfDiff + offDiag * offDiag)
        let lambda1 = halfTrace + delta
        let lambda2 = halfTrace - delta

        // If one local quadratic coefficient is near zero, this is parabola-like or degenerate.
        guard abs(lambda1) > epsilon, abs(lambda2) > epsilon else { return nil }

        // Convention: world = R(theta) * local + center
        let theta = 0.5 * Foundation.atan2(b, a - c)
        let center = Expr.tuple([.real(h), .real(k)])

        if lambda1 * lambda2 > 0 {
            let ratio1 = r / lambda1
            let ratio2 = r / lambda2
            guard ratio1 > epsilon, ratio2 > epsilon else { return nil }

            return .conic(
                ConicInfo(
                    kind: .ellipse,
                    source: source,
                    canonicalForm: .translatedEllipse(
                        center: center,
                        a: .function(.sqrt, arguments: [.real(ratio1)]),
                        b: .function(.sqrt, arguments: [.real(ratio2)])
                    ),
                    orientation: .rotated,
                    rotationAngle: theta
                )
            )
        }

        if lambda1 * lambda2 < 0 {
            let ratio1 = r / lambda1
            let ratio2 = r / lambda2

            if ratio1 > epsilon {
                let aSquared = ratio1
                let bSquared = abs(ratio2)
                guard bSquared > epsilon else { return nil }
                return .conic(
                    ConicInfo(
                        kind: .hyperbola,
                        source: source,
                        canonicalForm: .translatedHyperbolaX(
                            center: center,
                            a: .function(.sqrt, arguments: [.real(aSquared)]),
                            b: .function(.sqrt, arguments: [.real(bSquared)])
                        ),
                        orientation: .rotated,
                        rotationAngle: theta
                    )
                )
            }

            if ratio2 > epsilon {
                let bSquared = ratio2
                let aSquared = abs(ratio1)
                guard aSquared > epsilon else { return nil }
                return .conic(
                    ConicInfo(
                        kind: .hyperbola,
                        source: source,
                        canonicalForm: .translatedHyperbolaY(
                            center: center,
                            a: .function(.sqrt, arguments: [.real(aSquared)]),
                            b: .function(.sqrt, arguments: [.real(bSquared)])
                        ),
                        orientation: .rotated,
                        rotationAngle: theta
                    )
                )
            }
        }

        return nil
    }

    private func quadraticZeroForm(from expr: Expr) -> Expr {
        switch expr {
        case .equation(let left, let right):
            return .add([left, .negate(right)])
        case .relation(let left, let relation, let right) where relation == .equal:
            return .add([left, .negate(right)])
        default:
            return expr
        }
    }
}
