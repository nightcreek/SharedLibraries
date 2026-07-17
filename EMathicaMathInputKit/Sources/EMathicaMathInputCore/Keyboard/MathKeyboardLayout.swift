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
                        .template(
                            "numbers-div",
                            markup: "\\frac{\\placeholder{}}{\\placeholder{}}",
                            token: .fraction,
                            accessibilityLabel: "分数"
                        )
                    ]),
                    MathKeyboardRow(keys: [
                        .template(
                            "numbers-superscript-square",
                            markup: "x^{2}",
                            token: .superscript,
                            accessibilityLabel: "上标"
                        ),
                        .template(
                            "numbers-superscript-generic",
                            markup: "x^{y}",
                            token: .superscript,
                            accessibilityLabel: "指数"
                        ),
                        .template(
                            "numbers-sqrt",
                            markup: "\\sqrt{\\placeholder{}}",
                            token: .sqrt,
                            accessibilityLabel: "根号"
                        ),
                        .template(
                            "numbers-abs",
                            markup: "|\\placeholder{}|",
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
                            markup: "|\\placeholder{}|",
                            token: .absoluteValue,
                            accessibilityLabel: "绝对值"
                        ),
                        .template(
                            "functions-sqrt",
                            markup: "\\sqrt{\\placeholder{}}",
                            token: .sqrt,
                            accessibilityLabel: "根号"
                        ),
                        .template(
                            "functions-fraction",
                            markup: "\\frac{\\placeholder{}}{\\placeholder{}}",
                            token: .fraction,
                            accessibilityLabel: "分数"
                        )
                    ]),
                    MathKeyboardRow(keys: [
                        .template(
                            "functions-superscript",
                            markup: "x^{y}",
                            token: .superscript,
                            accessibilityLabel: "上标"
                        ),
                        .template(
                            "functions-subscript",
                            markup: "x_{n}",
                            token: .subscript,
                            accessibilityLabel: "下标"
                        ),
                        .legacyFormulaTemplate(
                            "functions-parametric-2d",
                            markup: "\\parametric{x(t)}{y(t)}{\\placeholder{}}",
                            accessibilityLabel: "参数方程",
                            kind: .parametricEquation2D
                        ),
                        .legacyFormulaTemplate(
                            "functions-piecewise",
                            markup: "\\piecewise{\\placeholder{}}{\\placeholder{}}{\\placeholder{}}{\\placeholder{}}",
                            accessibilityLabel: "分段函数",
                            kind: .piecewise(rows: 2)
                        ),
                        .template(
                            "functions-parentheses",
                            markup: "(\\placeholder{})",
                            token: .parentheses,
                            accessibilityLabel: "括号模板"
                        ),
                        .char("functions-open-paren", "("),
                        .char("functions-close-paren", ")"),
                        .op("functions-plus", title: "+", raw: "+"),
                        .op("functions-minus", title: "-", raw: "-")
                    ]),
                    MathKeyboardRow(keys: [
                        .char("functions-x", "x"),
                        .char("functions-y", "y"),
                        .char("functions-t", "t"),
                        .symbol("functions-pi", title: "π", raw: "\\pi", accessibilityLabel: "pi"),
                        .char("functions-e", "e"),
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
                rows: [
                    MathKeyboardRow(keys: [
                        .char("alphabet-a", "a"),
                        .char("alphabet-b", "b"),
                        .char("alphabet-c", "c"),
                        .char("alphabet-d", "d"),
                        .char("alphabet-n", "n"),
                        .char("alphabet-r", "r"),
                        .char("alphabet-h", "h"),
                        .char("alphabet-k", "k"),
                        .char("alphabet-m", "m")
                    ]),
                    MathKeyboardRow(keys: [
                        .char("alphabet-p", "p"),
                        .char("alphabet-q", "q"),
                        .char("alphabet-u", "u"),
                        .char("alphabet-v", "v"),
                        .char("alphabet-A", "A"),
                        .char("alphabet-B", "B"),
                        .char("alphabet-C", "C"),
                        .char("alphabet-D", "D"),
                        .char("alphabet-E", "E")
                    ]),
                    MathKeyboardRow(keys: [
                        .char("alphabet-f", "f"),
                        .char("alphabet-g", "g"),
                        .char("alphabet-i", "i"),
                        .char("alphabet-j", "j"),
                        .char("alphabet-l", "l"),
                        .char("alphabet-o", "o"),
                        .char("alphabet-s", "s"),
                        .char("alphabet-w", "w"),
                        .char("alphabet-z", "z")
                    ]),
                    MathKeyboardRow(keys: [
                        .system("alphabet-left", symbol: "←", action: .moveLeft, accessibilityLabel: "左移"),
                        .system("alphabet-right", symbol: "→", action: .moveRight, accessibilityLabel: "右移"),
                        .char("alphabet-comma", ","),
                        .char("alphabet-period", "."),
                        .char("alphabet-open-paren", "("),
                        .char("alphabet-close-paren", ")"),
                        .op("alphabet-eq", title: "=", raw: "="),
                        .system("alphabet-delete", symbol: "⌫", action: .deleteBackward, accessibilityLabel: "删除"),
                        .system("alphabet-submit", symbol: "↵", action: .submit, accessibilityLabel: "提交", accent: true)
                    ])
                ]
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
                        .op("symbols-div", title: "/", raw: "/"),
                        .op("symbols-eq", title: "=", raw: "="),
                        .char("symbols-comma", ",")
                    ]),
                    MathKeyboardRow(keys: [
                        .symbol("symbols-theta", title: "θ", raw: "\\theta", accessibilityLabel: "theta"),
                        .symbol("symbols-alpha", title: "α", raw: "\\alpha", accessibilityLabel: "alpha"),
                        .symbol("symbols-beta", title: "β", raw: "\\beta", accessibilityLabel: "beta"),
                        .symbol("symbols-infty", title: "∞", raw: "\\infty", accessibilityLabel: "infinity"),
                        .symbol("symbols-in", title: "∈", raw: "\\in", accessibilityLabel: "belongs to"),
                        .symbol("symbols-not-in", title: "∉", raw: "\\notin", accessibilityLabel: "not belongs to"),
                        .symbol("symbols-empty", title: "∅", raw: "\\emptyset", accessibilityLabel: "empty set"),
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
            label: .text(value),
            intent: .input(.char(value)),
            accessibilityLabel: value
        )
    }

    static func number(_ id: String, _ value: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .text(value),
            intent: .input(.number(value)),
            accessibilityLabel: value
        )
    }

    static func op(_ id: String, title: String, raw: String, accent: Bool = false) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .text(title),
            intent: .input(.op(raw)),
            accessibilityLabel: title + (accent ? " accent" : "")
        )
    }

    static func symbol(_ id: String, title: String, raw: String, accessibilityLabel: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .text(title),
            intent: .action(.insertSymbol(raw)),
            accessibilityLabel: accessibilityLabel
        )
    }

    static func function(_ id: String, _ name: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .text(name),
            intent: .input(.function(name)),
            accessibilityLabel: name
        )
    }

    static func template(
        _ id: String,
        markup: String,
        token: MathInputTemplateToken,
        accessibilityLabel: String
    ) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .formulaMarkup(markup),
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
        accessibilityLabel: String,
        kind: TemplateKind
    ) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .formulaMarkup(markup),
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
            label: .system(symbol),
            intent: .action(action),
            size: accent ? .wide : .normal,
            accessibilityLabel: accessibilityLabel
        )
    }
}
