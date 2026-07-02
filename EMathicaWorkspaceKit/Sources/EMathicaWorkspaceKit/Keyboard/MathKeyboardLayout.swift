import EMathicaMathInputCore

public enum MathKeyboardTab: String, CaseIterable, Identifiable {
    case numbers
    case functions
    case alphabet
    case symbols

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .numbers: return "123"
        case .functions: return "f(x)"
        case .alphabet: return "ABC"
        case .symbols: return "符号"
        }
    }

    public var rows: [[KeyboardKey]] {
        switch self {
        case .numbers:
            return [
                [.text("x"), .text("y"), .symbol("π", raw: "\\pi"), .text("e"), .text("7"), .text("8"), .text("9"), .op("×", raw: "*"), .op("÷", raw: "/")],
                [.template("x²", subtitle: "上标", kind: .superscript), .template("xʸ", subtitle: "指数", kind: .superscript), .template("√□", subtitle: "根号", kind: .sqrt), .template("|□|", subtitle: "绝对值", kind: .absoluteValue), .text("4"), .text("5"), .text("6"), .op("+", raw: "+"), .op("-", raw: "-")],
                [.op("<", raw: "<"), .op(">", raw: ">"), .op("≤", raw: "\\leq"), .op("≥", raw: "\\geq"), .text("1"), .text("2"), .text("3"), .op("=", raw: "=", accent: true), .deleteBackwardKey],
                [.function("sin"), .function("cos"), .function("tan"), .function("log"), .text("0"), .text("."), .moveLeftKey, .moveRightKey, .submitKey]
            ]
        case .functions:
            return [
                [.function("sin"), .function("cos"), .function("tan"), .function("ln"), .function("log"), .function("exp"), .template("|□|", subtitle: "abs", kind: .absoluteValue), .template("√□", subtitle: "根号", kind: .sqrt), .template("□⁄□", subtitle: "分数", kind: .fraction)],
                [.template("xʸ", subtitle: "上标", kind: .superscript), .template("xₙ", subtitle: "下标", kind: .subscriptTemplate), .template("x(t),y(t)", subtitle: "参数", kind: .parametricEquation2D), .template("分段", subtitle: "cases", kind: .piecewise(rows: 2)), .template("(□)", subtitle: "括号", kind: .parentheses), .text("("), .text(")"), .op("+", raw: "+"), .op("-", raw: "-")],
                [.text("x"), .text("y"), .text("t"), .symbol("π", raw: "\\pi"), .text("e"), .moveLeftKey, .moveRightKey, .deleteBackwardKey, .submitKey]
            ]
        case .alphabet:
            return [
                [.text("a"), .text("b"), .text("c"), .text("d"), .text("n"), .text("r"), .text("h"), .text("k"), .text("m")],
                [.text("p"), .text("q"), .text("u"), .text("v"), .text("A"), .text("B"), .text("C"), .text("D"), .text("E")],
                [.text("f"), .text("g"), .text("i"), .text("j"), .text("l"), .text("o"), .text("s"), .text("w"), .text("z")],
                [.moveLeftKey, .moveRightKey, .text(","), .text("."), .text("("), .text(")"), .op("=", raw: "="), .deleteBackwardKey, .submitKey]
            ]
        case .symbols:
            return [
                [.op("<", raw: "<"), .op(">", raw: ">"), .op("≤", raw: "\\leq"), .op("≥", raw: "\\geq"), .op("≠", raw: "\\neq"), .text("("), .text(")"), .text("["), .text("]")],
                [.text("|"), .text("{"), .text("}"), .op("+", raw: "+"), .op("-", raw: "-"), .op("×", raw: "*"), .op("÷", raw: "/"), .op("=", raw: "="), .text(",")],
                [.symbol("θ", raw: "\\theta"), .symbol("α", raw: "\\alpha"), .symbol("β", raw: "\\beta"), .symbol("∞", raw: "\\infty"), .symbol("∈", raw: "\\in"), .symbol("∉", raw: "\\notin"), .symbol("∅", raw: "\\emptyset"), .deleteBackwardKey, .submitKey]
            ]
        }
    }
}

private extension KeyboardKey {
    static var moveLeftKey: KeyboardKey { KeyboardKey.command("←", action: .moveLeft) }
    static var moveRightKey: KeyboardKey { KeyboardKey.command("→", action: .moveRight) }
    static var deleteBackwardKey: KeyboardKey { KeyboardKey.command("⌫", action: .deleteBackward) }
    static var submitKey: KeyboardKey { KeyboardKey.command("↵", action: .submit, accent: true) }
}
