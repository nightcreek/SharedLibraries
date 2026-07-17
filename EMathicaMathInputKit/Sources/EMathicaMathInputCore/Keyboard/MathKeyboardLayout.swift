import Foundation

public struct MathKeyboardLayout: Equatable, Sendable {
    public var panels: [MathKeyboardPanel]

    public init(panels: [MathKeyboardPanel]) {
        self.panels = panels
    }
}

public struct MathKeyboardPanel: Equatable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var rows: [MathKeyboardRow]

    public init(id: String, title: String, rows: [MathKeyboardRow]) {
        self.id = id
        self.title = title
        self.rows = rows
    }
}

public struct MathKeyboardRow: Equatable, Sendable {
    public var keys: [MathKeyboardKey]

    public init(keys: [MathKeyboardKey]) {
        self.keys = keys
    }
}

public enum MathKeyboardLayouts {
    public static let standard = MathKeyboardLayout(
        panels: [
            MathKeyboardPanel(
                id: "numbers",
                title: "123",
                rows: [
                    MathKeyboardRow(keys: [
                        .char("numbers-x", "x"),
                        .char("numbers-y", "y"),
                        .symbol("numbers-pi", title: "π", raw: "\\pi", accessibilityLabel: "pi"),
                        .char("numbers-e", "e"),
                        .number("numbers-7", "7"),
                        .number("numbers-8", "8"),
                        .number("numbers-9", "9"),
                        .op("numbers-mul", title: "×", raw: "*"),
                        .division("numbers-div", accessibilityLabel: "分数")
                    ]),
                    MathKeyboardRow(keys: [
                        .template(
                            "numbers-superscript-square",
                            markup: "x^{2}",
                            fallback: "x^2",
                            token: .superscript,
                            accessibilityLabel: "上标"
                        ),
                        .template(
                            "numbers-superscript-generic",
                            markup: "x^{n}",
                            fallback: "x^n",
                            token: .superscript,
                            accessibilityLabel: "指数"
                        ),
                        .template(
                            "numbers-sqrt",
                            markup: "\\sqrt{x}",
                            fallback: "√x",
                            token: .sqrt,
                            accessibilityLabel: "根号"
                        ),
                        .template(
                            "numbers-abs",
                            markup: "|x|",
                            fallback: "|x|",
                            token: .absoluteValue,
                            accessibilityLabel: "绝对值"
                        ),
                        .number("numbers-4", "4"),
                        .number("numbers-5", "5"),
                        .number("numbers-6", "6"),
                        .op("numbers-plus", title: "+", raw: "+"),
                        .op("numbers-minus", title: "-", raw: "-")
                    ]),
                    MathKeyboardRow(keys: [
                        .op("numbers-lt", title: "<", raw: "<"),
                        .op("numbers-gt", title: ">", raw: ">"),
                        .op("numbers-leq", title: "≤", raw: "\\leq"),
                        .op("numbers-geq", title: "≥", raw: "\\geq"),
                        .number("numbers-1", "1"),
                        .number("numbers-2", "2"),
                        .number("numbers-3", "3"),
                        .op("numbers-eq", title: "=", raw: "=", accent: true),
                        .system("numbers-delete", symbol: "⌫", action: .deleteBackward, accessibilityLabel: "删除")
                    ]),
                    MathKeyboardRow(keys: [
                        .function("numbers-sin", "sin"),
                        .function("numbers-cos", "cos"),
                        .function("numbers-tan", "tan"),
                        .function("numbers-log", "log"),
                        .number("numbers-0", "0"),
                        .char("numbers-dot", "."),
                        .system("numbers-left", symbol: "←", action: .moveLeft, accessibilityLabel: "左移"),
                        .system("numbers-right", symbol: "→", action: .moveRight, accessibilityLabel: "右移"),
                        .system("numbers-submit", symbol: "↵", action: .submit, accessibilityLabel: "提交", accent: true)
                    ])
                ]
            ),
            MathKeyboardPanel(
                id: "functions",
                title: "f(x)",
                rows: [
                    MathKeyboardRow(keys: [
                        .function("functions-sin", "sin"),
                        .function("functions-cos", "cos"),
                        .function("functions-tan", "tan"),
                        .function("functions-ln", "ln"),
                        .function("functions-log", "log"),
                        .function("functions-exp", "exp"),
                        .template(
                            "functions-abs",
                            markup: "|x|",
                            fallback: "|x|",
                            token: .absoluteValue,
                            accessibilityLabel: "绝对值"
                        ),
                        .template(
                            "functions-sqrt",
                            markup: "\\sqrt{x}",
                            fallback: "√x",
                            token: .sqrt,
                            accessibilityLabel: "根号"
                        ),
                        .template(
                            "functions-fraction",
                            markup: "\\frac{x}{y}",
                            fallback: "x/y",
                            token: .fraction,
                            accessibilityLabel: "分数"
                        )
                    ]),
                    MathKeyboardRow(keys: [
                        .template(
                            "functions-superscript",
                            markup: "x^{n}",
                            fallback: "x^n",
                            token: .superscript,
                            accessibilityLabel: "上标"
                        ),
                        .template(
                            "functions-subscript",
                            markup: "x_{n}",
                            fallback: "x_n",
                            token: .subscript,
                            accessibilityLabel: "下标"
                        ),
                        .legacyFormulaTemplate(
                            "functions-parametric-2d",
                            markup: "\\begin{cases}x=x(t)\\\\y=y(t)\\end{cases}",
                            fallback: "x(t), y(t)",
                            accessibilityLabel: "参数方程",
                            kind: .parametricEquation2D
                        ),
                        .legacyFormulaTemplate(
                            "functions-piecewise",
                            markup: "\\begin{cases}f\\left(x\\right)&\\\\\\ldots&\\end{cases}",
                            fallback: "cases",
                            accessibilityLabel: "分段函数",
                            kind: .piecewise(rows: 2)
                        ),
                        .template(
                            "functions-parentheses",
                            markup: "(x)",
                            fallback: "(x)",
                            token: .parentheses,
                            accessibilityLabel: "括号模板"
                        )
                    ]),
                    MathKeyboardRow(keys: [
                        .system("functions-left", symbol: "←", action: .moveLeft, accessibilityLabel: "左移"),
                        .system("functions-right", symbol: "→", action: .moveRight, accessibilityLabel: "右移"),
                        .system("functions-delete", symbol: "⌫", action: .deleteBackward, accessibilityLabel: "删除"),
                        .system("functions-submit", symbol: "↵", action: .submit, accessibilityLabel: "提交", accent: true)
                    ])
                ]
            ),
            MathKeyboardPanel(
                id: "alphabet",
                title: "ABC",
                rows: []
            ),
            MathKeyboardPanel(
                id: "symbols",
                title: "符号",
                rows: [
                    MathKeyboardRow(keys: [
                        .op("symbols-lt", title: "<", raw: "<"),
                        .op("symbols-gt", title: ">", raw: ">"),
                        .op("symbols-leq", title: "≤", raw: "\\leq"),
                        .op("symbols-geq", title: "≥", raw: "\\geq"),
                        .op("symbols-neq", title: "≠", raw: "\\neq"),
                        .char("symbols-open-paren", "("),
                        .char("symbols-close-paren", ")"),
                        .char("symbols-open-bracket", "["),
                        .char("symbols-close-bracket", "]")
                    ]),
                    MathKeyboardRow(keys: [
                        .char("symbols-bar", "|"),
                        .char("symbols-open-brace", "{"),
                        .char("symbols-close-brace", "}"),
                        .op("symbols-plus", title: "+", raw: "+"),
                        .op("symbols-minus", title: "-", raw: "-"),
                        .op("symbols-mul", title: "×", raw: "*"),
                        .division("symbols-div", accessibilityLabel: "分数"),
                        .op("symbols-eq", title: "=", raw: "="),
                        .char("symbols-comma", ",")
                    ]),
                    MathKeyboardRow(keys: [
                        .symbol("symbols-empty", title: "∅", raw: "\\varnothing", accessibilityLabel: "empty set"),
                        .symbol("symbols-cdot", title: "·", raw: "\\cdot", accessibilityLabel: "dot"),
                        .symbol("symbols-infty", title: "∞", raw: "\\infty", accessibilityLabel: "infinity"),
                        .symbol("symbols-in", title: "∈", raw: "\\in", accessibilityLabel: "belongs to"),
                        .symbol("symbols-not-in", title: "∉", raw: "\\notin", accessibilityLabel: "not belongs to"),
                        .symbol("symbols-approx", title: "≈", raw: "\\approx", accessibilityLabel: "approximately equal"),
                        .symbol("symbols-pm", title: "±", raw: "\\pm", accessibilityLabel: "plus or minus"),
                        .system("symbols-delete", symbol: "⌫", action: .deleteBackward, accessibilityLabel: "删除"),
                        .system("symbols-submit", symbol: "↵", action: .submit, accessibilityLabel: "提交", accent: true)
                    ])
                ]
            )
        ]
    )
}

private extension MathKeyboardKey {
    static func char(_ id: String, _ value: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .symbol(markup: literalMathMarkup(for: value), fallback: value),
            intent: .input(.char(value)),
            accessibilityLabel: value
        )
    }

    static func number(_ id: String, _ value: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .symbol(markup: literalMathMarkup(for: value), fallback: value),
            intent: .input(.number(value)),
            accessibilityLabel: value
        )
    }

    static func op(_ id: String, title: String, raw: String, accent: Bool = false) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .symbol(markup: symbolMarkup(title: title, raw: raw), fallback: title),
            intent: .input(.op(raw)),
            accessibilityLabel: title + (accent ? " accent" : "")
        )
    }

    static func symbol(_ id: String, title: String, raw: String, accessibilityLabel: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .symbol(markup: raw, fallback: title),
            intent: .action(.insertSymbol(raw)),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func division(_ id: String, accessibilityLabel: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .symbol(markup: #"\div"#, fallback: "÷"),
            intent: .input(.template(.fraction)),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func function(_ id: String, _ name: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .formula(markup: functionMarkup(for: name), fallback: functionFallback(for: name)),
            intent: .input(.function(name)),
            accessibilityLabel: name
        )
    }

    static func template(
        _ id: String,
        markup: String,
        fallback: String,
        token: MathInputTemplateToken,
        accessibilityLabel: String
    ) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .formula(markup: markup, fallback: fallback),
            intent: .input(.template(token)),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func legacyTemplate(
        _ id: String,
        title: String,
        accessibilityLabel: String,
        kind: TemplateKind
    ) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .text(title),
            intent: .action(.insertTemplate(kind)),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func legacyFormulaTemplate(
        _ id: String,
        markup: String,
        fallback: String,
        accessibilityLabel: String,
        kind: TemplateKind
    ) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .formula(markup: markup, fallback: fallback),
            intent: .action(.insertTemplate(kind)),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func system(
        _ id: String,
        symbol: String,
        action: KeyboardAction,
        accessibilityLabel: String,
        accent: Bool = false
    ) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .systemIcon(systemIconName(for: symbol)),
            intent: .action(action),
            size: accent ? .wide : .normal,
            accessibilityLabel: accessibilityLabel
        )
    }

    static func functionMarkup(for name: String) -> String {
        switch name {
        case "sin":
            return #"\sin(x)"#
        case "cos":
            return #"\cos(x)"#
        case "tan":
            return #"\tan(x)"#
        case "ln":
            return #"\ln(x)"#
        case "log":
            return #"\log(x)"#
        case "exp":
            return #"e^{x}"#
        default:
            return name
        }
    }

    static func functionFallback(for name: String) -> String {
        switch name {
        case "exp":
            return "e^x"
        default:
            return "\(name)(x)"
        }
    }

    static func symbolMarkup(title: String, raw: String) -> String {
        switch raw {
        case "*":
            return #"\times"#
        case "/":
            return #"\div"#
        case #"\leq"#:
            return #"\leq"#
        case #"\geq"#:
            return #"\geq"#
        case #"\neq"#:
            return #"\neq"#
        default:
            return literalMathMarkup(for: title)
        }
    }

    static func literalMathMarkup(for literal: String) -> String {
        switch literal {
        case "{":
            return #"\{"#
        case "}":
            return #"\}"#
        default:
            return literal
        }
    }

    static func systemIconName(for symbol: String) -> String {
        switch symbol {
        case "⌫":
            return "delete.left"
        case "↵":
            return "return.left"
        case "←":
            return "arrow.left"
        case "→":
            return "arrow.right"
        case "↑":
            return "arrow.up"
        case "↓":
            return "arrow.down"
        default:
            return symbol
        }
    }
}
