import Foundation

public enum PlaneAlgebraClassifier {
    public static func classify(_ relation: AlgebraRelation, rewriteInfo: ParametricRewriteInfo? = nil) -> AlgebraClassification {
        if let rewriteInfo {
            let curve = rewriteInfo.curve
            let shapeKind = rewriteInfo.shapeKind
            switch shapeKind {
            case .circle:
                return AlgebraClassification(kind: .circle, summary: "圆", renderExpression: nil, centerX: curve.centerX, centerY: curve.centerY, radius: curve.radiusX, radiusX: curve.radiusX, radiusY: curve.radiusY)
            case .ellipse:
                return AlgebraClassification(kind: .ellipse, summary: "椭圆", renderExpression: nil, centerX: curve.centerX, centerY: curve.centerY, radiusX: curve.radiusX, radiusY: curve.radiusY)
            case .hyperbola:
                return AlgebraClassification(kind: .hyperbola, summary: "双曲线", renderExpression: nil, centerX: curve.centerX, centerY: curve.centerY, radiusX: curve.radiusX, radiusY: curve.radiusY)
            case .parabola:
                return AlgebraClassification(kind: .parabola, summary: "抛物线", renderExpression: nil, centerX: curve.centerX, centerY: curve.centerY)
            case .superellipse:
                return AlgebraClassification(kind: .superellipse, summary: "超椭圆", renderExpression: nil, centerX: curve.centerX, centerY: curve.centerY, radiusX: curve.radiusX, radiusY: curve.radiusY)
            }
        }

        switch relation {
        case .expression(let expression):
            return AlgebraClassification(kind: .explicitY, summary: "显函数 y = f(x)", renderExpression: expression)
        case .equation(let equation):
            if isFunctionDefinition(equation.left, parameter: "x") {
                return explicitY(equation.right)
            }
            if isFunctionDefinition(equation.left, parameter: "y") {
                return explicitX(equation.right)
            }
            if isFunctionDefinition(equation.right, parameter: "x") {
                return explicitY(equation.left)
            }
            if isFunctionDefinition(equation.right, parameter: "y") {
                return explicitX(equation.left)
            }
            if case .symbol("y") = equation.left {
                return explicitY(equation.right)
            }
            if case .symbol("x") = equation.left {
                return explicitX(equation.right)
            }
            if case .symbol("y") = equation.right {
                return explicitY(equation.left)
            }
            if case .symbol("x") = equation.right {
                return explicitX(equation.left)
            }
            if let conic = classifyAxisAlignedConic(equation) {
                return conic
            }
            return AlgebraClassification(kind: .implicitPlaneCurve, summary: "一般隐式平面曲线")
        }
    }

    private static func isFunctionDefinition(_ expression: AlgebraExpression, parameter: String) -> Bool {
        guard case .function(let name, .symbol(parameter)) = expression else { return false }
        return !["sin", "cos", "tan", "sqrt", "abs", "log", "ln", "exp"].contains(name)
    }

    private static func explicitY(_ expression: AlgebraExpression) -> AlgebraClassification {
        if case .number(let y) = expression {
            return AlgebraClassification(kind: .horizontalLine, summary: "水平线", renderExpression: expression, centerY: y)
        }
        return AlgebraClassification(kind: .explicitY, summary: "显函数 y = f(x)", renderExpression: expression)
    }

    private static func explicitX(_ expression: AlgebraExpression) -> AlgebraClassification {
        if case .number(let x) = expression {
            return AlgebraClassification(kind: .verticalLine, summary: "竖直线", renderExpression: expression, centerX: x)
        }
        return AlgebraClassification(kind: .explicitX, summary: "显函数 x = f(y)", renderExpression: expression)
    }

    private static func classifyAxisAlignedConic(_ equation: AlgebraEquation) -> AlgebraClassification? {
        let implicit = AlgebraSimplifier.simplify(.add([equation.left, .multiply([.number(-1), equation.right])]))
        guard let poly = QuadraticPolynomial.make(from: implicit) else { return nil }
        guard poly.xy == 0 else { return nil }

        if let centered = classifyCenteredConic(poly) {
            return centered
        }
        if let parabola = classifyParabola(poly) {
            return parabola
        }
        return nil
    }

    private static func classifyCenteredConic(_ poly: QuadraticPolynomial) -> AlgebraClassification? {
        guard abs(poly.xx) > 0.000001, abs(poly.yy) > 0.000001 else { return nil }

        let centerX = -poly.x / (2 * poly.xx)
        let centerY = -poly.y / (2 * poly.yy)
        let shiftedConstant = poly.constant
            - (poly.x * poly.x) / (4 * poly.xx)
            - (poly.y * poly.y) / (4 * poly.yy)

        if poly.xx * poly.yy > 0 {
            let rx2 = -shiftedConstant / poly.xx
            let ry2 = -shiftedConstant / poly.yy
            guard rx2 > 0, ry2 > 0 else { return nil }
            let rx = sqrt(rx2)
            let ry = sqrt(ry2)
            if abs(rx - ry) < 0.000001 {
                return AlgebraClassification(kind: .circle, summary: "圆", centerX: centerX, centerY: centerY, radius: rx, radiusX: rx, radiusY: ry)
            }
            return AlgebraClassification(kind: .ellipse, summary: "椭圆", centerX: centerX, centerY: centerY, radiusX: rx, radiusY: ry)
        }

        guard shiftedConstant != 0 else {
            return AlgebraClassification(kind: .implicitPlaneCurve, summary: "退化双曲线")
        }
        return AlgebraClassification(kind: .hyperbola, summary: "双曲线", centerX: centerX, centerY: centerY)
    }

    private static func classifyParabola(_ poly: QuadraticPolynomial) -> AlgebraClassification? {
        if abs(poly.xx) > 0.000001, abs(poly.yy) < 0.000001, abs(poly.y) > 0.000001 {
            let vertexX = -poly.x / (2 * poly.xx)
            let shiftedConstant = poly.constant - (poly.x * poly.x) / (4 * poly.xx)
            let vertexY = -shiftedConstant / poly.y
            return AlgebraClassification(kind: .parabola, summary: "抛物线", centerX: vertexX, centerY: vertexY)
        }
        if abs(poly.yy) > 0.000001, abs(poly.xx) < 0.000001, abs(poly.x) > 0.000001 {
            let vertexY = -poly.y / (2 * poly.yy)
            let shiftedConstant = poly.constant - (poly.y * poly.y) / (4 * poly.yy)
            let vertexX = -shiftedConstant / poly.x
            return AlgebraClassification(kind: .parabola, summary: "抛物线", centerX: vertexX, centerY: vertexY)
        }
        return nil
    }
}

private struct QuadraticPolynomial {
    public var constant: Double = 0
    public var x: Double = 0
    public var y: Double = 0
    public var xx: Double = 0
    public var yy: Double = 0
    public var xy: Double = 0

    public static func make(from expression: AlgebraExpression) -> QuadraticPolynomial? {
        var result = QuadraticPolynomial()
        guard result.add(expression, coefficient: 1) else { return nil }
        return result
    }

    private mutating func add(_ expression: AlgebraExpression, coefficient: Double) -> Bool {
        switch expression {
        case .number(let value):
            constant += coefficient * value
            return true
        case .symbol("x"):
            x += coefficient
            return true
        case .symbol("y"):
            y += coefficient
            return true
        case .add(let terms):
            for term in terms {
                guard add(term, coefficient: coefficient) else { return false }
            }
            return true
        case .multiply(let factors):
            var coeff = coefficient
            var symbols: [String] = []
            for factor in factors {
                switch factor {
                case .number(let value):
                    coeff *= value
                case .symbol(let name):
                    symbols.append(name)
                case .power(.symbol(let name), .number(let exponent)) where exponent == 2:
                    symbols.append(name)
                    symbols.append(name)
                default:
                    return false
                }
            }
            return addMonomial(symbols.sorted(), coefficient: coeff)
        case .divide(let numerator, .number(let denominator)) where denominator != 0:
            return add(numerator, coefficient: coefficient / denominator)
        case .power(.symbol(let name), .number(let exponent)) where exponent == 2:
            return addMonomial([name, name], coefficient: coefficient)
        default:
            return false
        }
    }

    private mutating func addMonomial(_ symbols: [String], coefficient: Double) -> Bool {
        switch symbols {
        case []:
            constant += coefficient
        case ["x"]:
            x += coefficient
        case ["y"]:
            y += coefficient
        case ["x", "x"]:
            xx += coefficient
        case ["y", "y"]:
            yy += coefficient
        case ["x", "y"]:
            xy += coefficient
        default:
            return false
        }
        return true
    }
}
