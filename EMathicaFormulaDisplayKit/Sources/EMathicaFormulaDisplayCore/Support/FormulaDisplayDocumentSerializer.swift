import Foundation

public enum FormulaDisplayDocumentSerializer {
    public static func serialize(_ document: FormulaDisplayDocument) -> String {
        serialize(document.root)
    }

    public static func serialize(_ node: FormulaDisplayNode) -> String {
        switch node {
        case .sequence(let children):
            return children.map(serialize).joined()
        case .text(let value, _):
            return value
        case .operatorSymbol(let value):
            return serializeOperator(value)
        case .function(let name, let arguments):
            return serializeFunction(name: name, arguments: arguments)
        case .fraction(let numerator, let denominator):
            return #"\frac{\#(serialize(numerator))}{\#(serialize(denominator))}"#
        case .sqrt(let radicand):
            return #"\sqrt{\#(serialize(radicand))}"#
        case .nthRoot(let index, let radicand):
            return #"\sqrt[\#(serialize(index))]{\#(serialize(radicand))}"#
        case .superscript(let base, let exponent):
            return "\(serialize(base))^{\(serialize(exponent))}"
        case .subscript(let base, let subscriptNode):
            return "\(serialize(base))_{\(serialize(subscriptNode))}"
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            var output = serialize(base)
            if let superscriptNode {
                output += "^{\(serialize(superscriptNode))}"
            }
            if let subscriptNode {
                output += "_{\(serialize(subscriptNode))}"
            }
            return output
        case .parentheses(let content):
            return "(\(serialize(content)))"
        case .brackets(let content):
            return "[\(serialize(content))]"
        case .braces(let content):
            return #"\{\#(serialize(content))\}"#
        case .absoluteValue(let content):
            return "|\(serialize(content))|"
        case .accent(let style, let content):
            switch style {
            case .vector:
                return #"\vec{\#(serialize(content))}"#
            case .overline:
                return #"\overline{\#(serialize(content))}"#
            case .hat:
                return #"\hat{\#(serialize(content))}"#
            }
        case .matrix(let environment, let rows):
            let body = rows
                .map { row in row.cells.map(serialize).joined(separator: "&") }
                .joined(separator: #"\\\\"#)
            return #"\begin{\#(matrixEnvironmentName(environment))}\#(body)\end{\#(matrixEnvironmentName(environment))}"#
        case .cases(let rows):
            let body = rows
                .map { row in row.cells.map(serialize).joined(separator: "&") }
                .joined(separator: #"\\\\"#)
            return #"\begin{cases}\#(body)\end{cases}"#
        case .limit(let variable, let target, let body):
            return #"\lim_{\#(serialize(variable))\to\#(serialize(target))} \#(serialize(body))"#
        case .largeOperator(let kind, let variable, let lowerBound, let upperBound, let body):
            let command = kind == .sum ? #"\sum"# : #"\prod"#
            return #"\#(command)_{\#(serialize(variable))=\#(serialize(lowerBound))}^{\#(serialize(upperBound))} \#(serialize(body))"#
        case .integral(let lowerBound, let upperBound, let integrand, let variable):
            return #"\int_{\#(serialize(lowerBound))}^{\#(serialize(upperBound))} \#(serialize(integrand))\,d\#(serialize(variable))"#
        case .parametric2D(let x, let y, let range):
            let body = #"\begin{cases}x=\#(serialize(x))\\y=\#(serialize(y))\end{cases}"#
            guard let range else { return body }
            return body + #",\ t\in \#(serialize(range))"#
        case .parametric3D(let x, let y, let z):
            return #"\begin{cases}x=\#(serialize(x))\\y=\#(serialize(y))\\z=\#(serialize(z))\end{cases}"#
        case .piecewise(let rows):
            let rowMarkup = rows
                .map { "\((serialize($0.expression))),&\((serialize($0.condition)))" }
                .joined(separator: #"\\\\"#)
            return #"\begin{cases}\#(rowMarkup)\end{cases}"#
        case .cursor:
            return #"\cursor{}"#
        case .placeholder:
            return #"\placeholder{}"#
        case .insertionMarker:
            return #"\eminsertion{}"#
        case .raw(let value):
            return value
        case .error(let node):
            return node.rawText
        }
    }

    private static func serializeFunction(name: String, arguments: [FormulaDisplayNode]) -> String {
        guard let first = arguments.first else {
            return "\\\(name)"
        }

        let parenthesizedFunctions: Set<String> = [
            "sin", "cos", "tan", "cot", "sec", "csc",
            "arcsin", "arccos", "arctan",
            "sinh", "cosh", "tanh",
            "ln", "lg", "log", "exp"
        ]

        if name == "log", arguments.count > 1 {
            return #"\log_{\#(serialize(arguments[0]))}(\#(serialize(arguments[1]))"#
                + ")"
        }

        if parenthesizedFunctions.contains(name) {
            return #"\#(name)(\#(serialize(first)))"#
        }

        let trailing = arguments.dropFirst().map { "{\(serialize($0))}" }.joined()
        return "\\\(name){\(serialize(first))}\(trailing)"
    }

    private static func matrixEnvironmentName(_ environment: FormulaMatrixEnvironment) -> String {
        switch environment {
        case .matrix:
            return "matrix"
        case .pmatrix:
            return "pmatrix"
        case .bmatrix:
            return "bmatrix"
        case .vmatrix:
            return "vmatrix"
        case .Vmatrix:
            return "Vmatrix"
        case .smallmatrix:
            return "smallmatrix"
        }
    }

    private static func serializeOperator(_ value: String) -> String {
        switch value {
        case "*":
            return #"\cdot"#
        default:
            return value
        }
    }
}
