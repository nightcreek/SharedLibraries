import EMathicaMathInputCore

enum MathKeyboardAlphabetScript: Equatable {
    case latin
    case greek
}

enum MathKeyboardLetterCase: Equatable {
    case lowercase
    case uppercase
}

struct MathInputKeyboardSurfaceModel: Equatable {
    static let alphabetPanelID = "alphabet"
    static let caseToggleKeyID = "alphabet-toggle-case"
    static let scriptToggleKeyID = "alphabet-toggle-script"

    let layout: MathKeyboardLayout
    var selectedPanelID: String
    var alphabetScript: MathKeyboardAlphabetScript
    var letterCase: MathKeyboardLetterCase

    init(
        layout: MathKeyboardLayout,
        selectedPanelID: String? = nil,
        alphabetScript: MathKeyboardAlphabetScript = .latin,
        letterCase: MathKeyboardLetterCase = .lowercase
    ) {
        self.layout = layout
        self.selectedPanelID = selectedPanelID ?? layout.panels.first?.id ?? ""
        self.alphabetScript = alphabetScript
        self.letterCase = letterCase
    }

    var visiblePanel: MathKeyboardPanel? {
        guard let panel = layout.panels.first(where: { $0.id == selectedPanelID }) ?? layout.panels.first else {
            return nil
        }
        guard panel.id == Self.alphabetPanelID else {
            return panel
        }
        return MathKeyboardPanel(id: panel.id, title: panel.title, rows: alphabetRows)
    }

    var alphabetRows: [MathKeyboardRow] {
        alphabetLetterRows + [MathKeyboardRow(keys: alphabetControlKeys)]
    }

    var currentAlphabetKeys: [MathKeyboardKey] {
        alphabetLetterRows.flatMap(\.keys).filter { !isAlphabetToggleKey($0) }
    }

    var alphabetLetterRows: [MathKeyboardRow] {
        switch (alphabetScript, letterCase) {
        case (.latin, .lowercase):
            return Self.latinLowercaseRows
        case (.latin, .uppercase):
            return Self.latinUppercaseRows
        case (.greek, .lowercase):
            return Self.greekLowercaseRows
        case (.greek, .uppercase):
            return Self.greekUppercaseRows
        }
    }

    var alphabetControlKeys: [MathKeyboardKey] {
        [
            Self.charKey(id: "alphabet-open-paren", displayMarkup: "(", input: "("),
            Self.charKey(id: "alphabet-close-paren", displayMarkup: ")", input: ")"),
            Self.charKey(id: "alphabet-comma", displayMarkup: ",", input: ","),
            Self.charKey(id: "alphabet-period", displayMarkup: ".", input: "."),
            Self.systemKey(id: "alphabet-left", symbol: "←", action: .moveLeft, accessibilityLabel: "左移"),
            Self.systemKey(id: "alphabet-right", symbol: "→", action: .moveRight, accessibilityLabel: "右移"),
            Self.systemKey(id: "alphabet-delete", symbol: "⌫", action: .deleteBackward, accessibilityLabel: "删除"),
            Self.systemKey(id: "alphabet-submit", symbol: "↵", action: .submit, accessibilityLabel: "提交", accent: true)
        ]
    }

    mutating func select(panelID: String) {
        guard layout.panels.contains(where: { $0.id == panelID }) else { return }
        selectedPanelID = panelID
    }

    mutating func toggleLetterCase() {
        letterCase = letterCase == .lowercase ? .uppercase : .lowercase
    }

    mutating func toggleAlphabetScript() {
        alphabetScript = alphabetScript == .latin ? .greek : .latin
    }

    func key(for id: String) -> MathKeyboardKey? {
        visiblePanel?.rows.flatMap(\.keys).first(where: { $0.id == id })
    }

    func isAlphabetToggleKey(_ key: MathKeyboardKey) -> Bool {
        key.id == Self.caseToggleKeyID || key.id == Self.scriptToggleKeyID
    }

    mutating func handle(_ key: MathKeyboardKey, forwarding handler: (MathKeyboardIntent) -> Void) {
        switch key.id {
        case Self.caseToggleKeyID:
            toggleLetterCase()
        case Self.scriptToggleKeyID:
            toggleAlphabetScript()
        default:
            forward(key.intent, to: handler)
        }
    }

    func forward(_ intent: MathKeyboardIntent, to handler: (MathKeyboardIntent) -> Void) {
        guard intent != .none else { return }
        handler(intent)
    }
}

private extension MathInputKeyboardSurfaceModel {
    static let latinLowercaseRows: [MathKeyboardRow] = keyboardRows(
        [
            latinKeys(values: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], uppercase: false),
            latinKeys(values: ["a", "s", "d", "f", "g", "h", "j", "k", "l"], uppercase: false),
            [caseToggleKey(for: .lowercase)] +
                latinKeys(values: ["z", "x", "c", "v", "b", "n", "m"], uppercase: false) +
                [scriptToggleKey(for: .latin)]
        ]
    )

    static let latinUppercaseRows: [MathKeyboardRow] = keyboardRows(
        [
            latinKeys(values: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"], uppercase: true),
            latinKeys(values: ["A", "S", "D", "F", "G", "H", "J", "K", "L"], uppercase: true),
            [caseToggleKey(for: .uppercase)] +
                latinKeys(values: ["Z", "X", "C", "V", "B", "N", "M"], uppercase: true) +
                [scriptToggleKey(for: .latin)]
        ]
    )

    static let greekLowercaseRows: [MathKeyboardRow] = keyboardRows(
        [
            greekKeys(entries: lowercaseGreekEntries),
            greekKeys(entries: lowercaseGreekEntriesSecondRow),
            [caseToggleKey(for: .lowercase)] +
                greekKeys(entries: lowercaseGreekEntriesThirdRow) +
                [scriptToggleKey(for: .greek)]
        ]
    )

    static let greekUppercaseRows: [MathKeyboardRow] = keyboardRows(
        [
            greekKeys(entries: uppercaseGreekEntries),
            greekKeys(entries: uppercaseGreekEntriesSecondRow),
            [caseToggleKey(for: .uppercase)] +
                greekKeys(entries: uppercaseGreekEntriesThirdRow) +
                [scriptToggleKey(for: .greek)]
        ]
    )

    static let lowercaseGreekEntries: [GreekKeyEntry] = [
        .symbol(command: "alpha", fallback: "α"),
        .symbol(command: "beta", fallback: "β"),
        .symbol(command: "gamma", fallback: "γ"),
        .symbol(command: "delta", fallback: "δ"),
        .symbol(command: "epsilon", fallback: "ε"),
        .symbol(command: "zeta", fallback: "ζ"),
        .symbol(command: "eta", fallback: "η"),
        .symbol(command: "theta", fallback: "θ"),
        .symbol(command: "iota", fallback: "ι"),
        .symbol(command: "kappa", fallback: "κ")
    ]

    static let lowercaseGreekEntriesSecondRow: [GreekKeyEntry] = [
        .symbol(command: "lambda", fallback: "λ"),
        .symbol(command: "mu", fallback: "μ"),
        .symbol(command: "nu", fallback: "ν"),
        .symbol(command: "xi", fallback: "ξ"),
        .symbol(command: "omicron", fallback: "ο"),
        .symbol(command: "pi", fallback: "π"),
        .symbol(command: "rho", fallback: "ρ"),
        .symbol(command: "sigma", fallback: "σ"),
        .symbol(command: "tau", fallback: "τ")
    ]

    static let lowercaseGreekEntriesThirdRow: [GreekKeyEntry] = [
        .symbol(command: "upsilon", fallback: "υ"),
        .symbol(command: "phi", fallback: "φ"),
        .symbol(command: "chi", fallback: "χ"),
        .symbol(command: "psi", fallback: "ψ"),
        .symbol(command: "omega", fallback: "ω")
    ]

    static let uppercaseGreekEntries: [GreekKeyEntry] = [
        .sharedGlyph(markup: "A", fallback: "A"),
        .sharedGlyph(markup: "B", fallback: "B"),
        .symbol(command: "Gamma", fallback: "Γ"),
        .symbol(command: "Delta", fallback: "Δ"),
        .sharedGlyph(markup: "E", fallback: "E"),
        .sharedGlyph(markup: "Z", fallback: "Z"),
        .sharedGlyph(markup: "H", fallback: "H"),
        .symbol(command: "Theta", fallback: "Θ"),
        .sharedGlyph(markup: "I", fallback: "I"),
        .sharedGlyph(markup: "K", fallback: "K")
    ]

    static let uppercaseGreekEntriesSecondRow: [GreekKeyEntry] = [
        .symbol(command: "Lambda", fallback: "Λ"),
        .sharedGlyph(markup: "M", fallback: "M"),
        .sharedGlyph(markup: "N", fallback: "N"),
        .symbol(command: "Xi", fallback: "Ξ"),
        .sharedGlyph(markup: "O", fallback: "O"),
        .symbol(command: "Pi", fallback: "Π"),
        .sharedGlyph(markup: "P", fallback: "P"),
        .symbol(command: "Sigma", fallback: "Σ"),
        .sharedGlyph(markup: "T", fallback: "T")
    ]

    static let uppercaseGreekEntriesThirdRow: [GreekKeyEntry] = [
        .sharedGlyph(markup: "Y", fallback: "Y"),
        .symbol(command: "Phi", fallback: "Φ"),
        .sharedGlyph(markup: "X", fallback: "X"),
        .symbol(command: "Psi", fallback: "Ψ"),
        .symbol(command: "Omega", fallback: "Ω")
    ]

    static func keyboardRows(_ rows: [[MathKeyboardKey]]) -> [MathKeyboardRow] {
        rows.map(MathKeyboardRow.init(keys:))
    }

    static func latinKeys(values: [String], uppercase: Bool) -> [MathKeyboardKey] {
        values.map { value in
            MathKeyboardKey(
                id: "alphabet-latin-\(uppercase ? "upper" : "lower")-\(value)",
                label: .symbol(markup: literalMathMarkup(for: value), fallback: value),
                intent: .input(.char(value)),
                accessibilityLabel: value
            )
        }
    }

    static func greekKeys(entries: [GreekKeyEntry]) -> [MathKeyboardKey] {
        entries.map { entry in
            MathKeyboardKey(
                id: "alphabet-greek-\(entry.identifier)",
                label: .symbol(markup: entry.markup, fallback: entry.fallback),
                intent: entry.intent,
                accessibilityLabel: entry.accessibilityLabel
            )
        }
    }

    static func caseToggleKey(for letterCase: MathKeyboardLetterCase) -> MathKeyboardKey {
        MathKeyboardKey(
            id: caseToggleKeyID,
            label: .formula(markup: "A/a", fallback: "A/a"),
            intent: .none,
            size: .wide,
            accessibilityLabel: "切换大小写"
        )
    }

    static func scriptToggleKey(for script: MathKeyboardAlphabetScript) -> MathKeyboardKey {
        MathKeyboardKey(
            id: scriptToggleKeyID,
            label: .formula(markup: #"a/\alpha"#, fallback: "a/α"),
            intent: .none,
            size: .wide,
            accessibilityLabel: "切换字母脚本"
        )
    }

    static func charKey(id: String, displayMarkup: String, input: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .symbol(markup: literalMathMarkup(for: displayMarkup), fallback: input),
            intent: .input(.char(input)),
            accessibilityLabel: input
        )
    }

    static func systemKey(
        id: String,
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

private extension MathInputKeyboardSurfaceModel {
    struct GreekKeyEntry: Equatable {
        let identifier: String
        let markup: String
        let fallback: String
        let intent: MathKeyboardIntent
        let accessibilityLabel: String

        static func symbol(command: String, fallback: String) -> GreekKeyEntry {
            GreekKeyEntry(
                identifier: command.lowercased(),
                markup: "\\\(command)",
                fallback: fallback,
                intent: .action(.insertSymbol("\\\(command)")),
                accessibilityLabel: fallback
            )
        }

        static func sharedGlyph(markup: String, fallback: String) -> GreekKeyEntry {
            GreekKeyEntry(
                identifier: "shared-\(fallback)",
                markup: markup,
                fallback: fallback,
                intent: .input(.char(fallback)),
                accessibilityLabel: fallback
            )
        }
    }
}
