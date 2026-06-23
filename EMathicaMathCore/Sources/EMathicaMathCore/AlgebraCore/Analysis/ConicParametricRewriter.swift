import Foundation

public enum ConicParametricRewriter {
    public static func recognize(_ relation: AlgebraRelation) -> ParametricRewriteInfo? {
        guard case .equation(let equation) = relation else { return nil }
        let implicit = AlgebraSimplifier.simplify(.add([equation.left, .multiply([.number(-1), equation.right])]))
        guard let poly = AxisAlignedQuadraticPolynomial.make(from: implicit), abs(poly.xy) < 0.000001 else {
            return nil
        }

        if let centered = recognizeCenteredConic(poly) {
            return centered
        }
        return recognizeParabola(poly)
    }

    private static func recognizeCenteredConic(_ poly: AxisAlignedQuadraticPolynomial) -> ParametricRewriteInfo? {
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
            let radiusX = sqrt(rx2)
            let radiusY = sqrt(ry2)
            let shape: RecognizedShapeKind = abs(radiusX - radiusY) < 0.000001 ? .circle : .ellipse
            let kind: ParametricCurveDefinition.Kind = shape == .circle ? .circle : .ellipse

            return ParametricRewriteInfo(
                shapeKind: shape,
                curve: ParametricCurveDefinition(
                    kind: kind,
                    centerX: centerX,
                    centerY: centerY,
                    radiusX: radiusX,
                    radiusY: radiusY,
                    exponent: 2,
                    radiusXSymbol: nil,
                    radiusYSymbol: nil,
                    exponentSymbol: nil,
                    focalParameter: nil,
                    tMin: 0,
                    tMax: 2 * Double.pi
                ),
                summary: shape == .circle ? "圆参数化" : "椭圆参数化"
            )
        }

        if poly.xx * shiftedConstant < 0 {
            let radiusX2 = -shiftedConstant / poly.xx
            let radiusY2 = shiftedConstant / poly.yy
            guard radiusX2 > 0, radiusY2 > 0 else { return nil }
            return hyperbola(
                kind: .hyperbolaHorizontal,
                centerX: centerX,
                centerY: centerY,
                radiusX: sqrt(radiusX2),
                radiusY: sqrt(radiusY2)
            )
        }

        if poly.yy * shiftedConstant < 0 {
            let radiusY2 = -shiftedConstant / poly.yy
            let radiusX2 = shiftedConstant / poly.xx
            guard radiusX2 > 0, radiusY2 > 0 else { return nil }
            return hyperbola(
                kind: .hyperbolaVertical,
                centerX: centerX,
                centerY: centerY,
                radiusX: sqrt(radiusX2),
                radiusY: sqrt(radiusY2)
            )
        }

        return nil
    }

    private static func recognizeParabola(_ poly: AxisAlignedQuadraticPolynomial) -> ParametricRewriteInfo? {
        if abs(poly.xx) > 0.000001, abs(poly.yy) < 0.000001, abs(poly.y) > 0.000001 {
            let vertexX = -poly.x / (2 * poly.xx)
            let shiftedConstant = poly.constant - (poly.x * poly.x) / (4 * poly.xx)
            let vertexY = -shiftedConstant / poly.y
            let p = -poly.y / (4 * poly.xx)
            guard p.isFinite, abs(p) > 0.000001 else { return nil }
            return parabola(
                kind: .parabolaVertical,
                centerX: vertexX,
                centerY: vertexY,
                p: p
            )
        }

        if abs(poly.yy) > 0.000001, abs(poly.xx) < 0.000001, abs(poly.x) > 0.000001 {
            let vertexY = -poly.y / (2 * poly.yy)
            let shiftedConstant = poly.constant - (poly.y * poly.y) / (4 * poly.yy)
            let vertexX = -shiftedConstant / poly.x
            let p = -poly.x / (4 * poly.yy)
            guard p.isFinite, abs(p) > 0.000001 else { return nil }
            return parabola(
                kind: .parabolaHorizontal,
                centerX: vertexX,
                centerY: vertexY,
                p: p
            )
        }

        return nil
    }

    private static func hyperbola(
        kind: ParametricCurveDefinition.Kind,
        centerX: Double,
        centerY: Double,
        radiusX: Double,
        radiusY: Double
    ) -> ParametricRewriteInfo {
        ParametricRewriteInfo(
            shapeKind: .hyperbola,
            curve: ParametricCurveDefinition(
                kind: kind,
                centerX: centerX,
                centerY: centerY,
                radiusX: radiusX,
                radiusY: radiusY,
                exponent: 2,
                radiusXSymbol: nil,
                radiusYSymbol: nil,
                exponentSymbol: nil,
                focalParameter: nil,
                tMin: -3,
                tMax: 3
            ),
            summary: "双曲线参数化"
        )
    }

    private static func parabola(
        kind: ParametricCurveDefinition.Kind,
        centerX: Double,
        centerY: Double,
        p: Double
    ) -> ParametricRewriteInfo {
        ParametricRewriteInfo(
            shapeKind: .parabola,
            curve: ParametricCurveDefinition(
                kind: kind,
                centerX: centerX,
                centerY: centerY,
                radiusX: abs(p),
                radiusY: abs(p),
                exponent: 2,
                radiusXSymbol: nil,
                radiusYSymbol: nil,
                exponentSymbol: nil,
                focalParameter: p,
                tMin: -8,
                tMax: 8
            ),
            summary: "抛物线参数化"
        )
    }
}

private struct AxisAlignedQuadraticPolynomial {
    public var constant: Double = 0
    public var x: Double = 0
    public var y: Double = 0
    public var xx: Double = 0
    public var yy: Double = 0
    public var xy: Double = 0

    public static func make(from expression: AlgebraExpression) -> AxisAlignedQuadraticPolynomial? {
        var result = AxisAlignedQuadraticPolynomial()
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
            var rest: [AlgebraExpression] = []
            for factor in factors {
                switch factor {
                case .number(let value):
                    coeff *= value
                default:
                    rest.append(factor)
                }
            }
            if rest.count == 1 {
                return add(rest[0], coefficient: coeff)
            }

            var symbols: [String] = []
            for factor in rest {
                switch factor {
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
        case .power(let base, .number(let exponent)) where exponent == 2:
            guard let linear = LinearPolynomial.make(from: base) else { return false }
            addLinearSquare(linear, coefficient: coefficient)
            return true
        default:
            return false
        }
    }

    private mutating func addLinearSquare(_ linear: LinearPolynomial, coefficient: Double) {
        constant += coefficient * linear.constant * linear.constant
        x += coefficient * 2 * linear.constant * linear.x
        y += coefficient * 2 * linear.constant * linear.y
        xx += coefficient * linear.x * linear.x
        yy += coefficient * linear.y * linear.y
        xy += coefficient * 2 * linear.x * linear.y
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

private struct LinearPolynomial {
    public var constant: Double = 0
    public var x: Double = 0
    public var y: Double = 0

    public static func make(from expression: AlgebraExpression) -> LinearPolynomial? {
        var result = LinearPolynomial()
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
            var rest: [AlgebraExpression] = []
            for factor in factors {
                if case .number(let value) = factor {
                    coeff *= value
                } else {
                    rest.append(factor)
                }
            }
            guard rest.count == 1 else { return false }
            return add(rest[0], coefficient: coeff)
        case .divide(let numerator, .number(let denominator)) where denominator != 0:
            return add(numerator, coefficient: coefficient / denominator)
        default:
            return false
        }
    }
}
