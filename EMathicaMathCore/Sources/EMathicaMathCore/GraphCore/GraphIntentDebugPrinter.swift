public struct GraphIntentDebugPrinter {
    private let exprPrinter = ExprDebugPrinter()

    public init() {}

    public func print(_ intent: GraphIntent) -> String {
        switch intent {
        case .explicitY(let expression, let variable):
            return "explicitY(expr:\(exprPrinter.print(expression)), var:\(variable.name))"
        case .explicitX(let expression, let variable):
            return "explicitX(expr:\(exprPrinter.print(expression)), var:\(variable.name))"
        case .implicit(let relation):
            return "implicit(\(exprPrinter.print(relation)))"
        case .parametric2D(let x, let y, let parameter, let range):
            return "parametric2D(x:\(exprPrinter.print(x)), y:\(exprPrinter.print(y)), t:\(parameter.name), range:\(rangeDescription(range)))"
        case .polar(let radius, let angle, let range):
            return "polar(r:\(exprPrinter.print(radius)), angle:\(angle.name), range:\(rangeDescription(range)))"
        case .point(let x, let y):
            return "point(x:\(exprPrinter.print(x)), y:\(exprPrinter.print(y)))"
        case .circle(let center, let radius):
            return "circle(center:\(exprPrinter.print(center)), radius:\(exprPrinter.print(radius)))"
        case .conic(let info):
            return "conic(kind:\(info.kind.rawValue), source:\(exprPrinter.print(info.source)))"
        case .piecewise(let branches):
            let rendered = branches.map { branch in
                "{cond:\(exprPrinter.print(branch.condition)), intent:\(print(branch.intent))}"
            }.joined(separator: ", ")
            return "piecewise([\(rendered)])"
        case .unknown(let expr):
            return "unknown(\(exprPrinter.print(expr)))"
        }
    }

    private func rangeDescription(_ range: ParameterRange?) -> String {
        guard let range else { return "nil" }
        let lower = range.lower.map(exprPrinter.print) ?? "nil"
        let upper = range.upper.map(exprPrinter.print) ?? "nil"
        return "[\(lower), \(upper)]"
    }
}
