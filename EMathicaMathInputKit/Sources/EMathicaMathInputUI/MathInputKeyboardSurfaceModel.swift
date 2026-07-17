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
            greekKeys(commands: ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa"], uppercase: false),
            greekKeys(commands: ["lambda", "mu", "nu", "xi", "omicron", "pi", "rho", "sigma", "tau"], uppercase: false),
            [caseToggleKey(for: .lowercase)] +
                greekKeys(commands: ["upsilon", "phi", "chi", "psi", "omega"], uppercase: false) +
                [scriptToggleKey(for: .greek)]
        ]
    )

    static let greekUppercaseRows: [MathKeyboardRow] = keyboardRows(
        [
            greekKeys(commands: ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa"], uppercase: true),
            greekKeys(commands: ["Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau"], uppercase: true),
            [caseToggleKey(for: .uppercase)] +
                greekKeys(commands: ["Upsilon", "Phi", "Chi", "Psi", "Omega"], uppercase: true) +
                [scriptToggleKey(for: .greek)]
        ]
    )

    static func keyboardRows(_ rows: [[MathKeyboardKey]]) -> [MathKeyboardRow] {
        rows.map(MathKeyboardRow.init(keys:))
    }

    static func latinKeys(values: [String], uppercase: Bool) -> [MathKeyboardKey] {
        values.map { value in
            MathKeyboardKey(
                id: "alphabet-latin-\(uppercase ? "upper" : "lower")-\(value)",
                label: .formulaMarkup(value),
                intent: .input(.char(value)),
                accessibilityLabel: value
            )
        }
    }

    static func greekKeys(commands: [String], uppercase: Bool) -> [MathKeyboardKey] {
        commands.map { command in
            MathKeyboardKey(
                id: "alphabet-greek-\(uppercase ? "upper" : "lower")-\(command)",
                label: .formulaMarkup("\\\(command)"),
                intent: .action(.insertSymbol("\\\(command)")),
                accessibilityLabel: command
            )
        }
    }

    static func caseToggleKey(for letterCase: MathKeyboardLetterCase) -> MathKeyboardKey {
        MathKeyboardKey(
            id: caseToggleKeyID,
            label: .formulaMarkup("Aa"),
            intent: .none,
            size: .wide,
            accessibilityLabel: "切换大小写"
        )
    }

    static func scriptToggleKey(for script: MathKeyboardAlphabetScript) -> MathKeyboardKey {
        MathKeyboardKey(
            id: scriptToggleKeyID,
            label: .formulaMarkup(script == .latin ? #"a/\alpha"# : #"a/\alpha"#),
            intent: .none,
            size: .wide,
            accessibilityLabel: "切换字母脚本"
        )
    }

    static func charKey(id: String, displayMarkup: String, input: String) -> MathKeyboardKey {
        MathKeyboardKey(
            id: id,
            label: .formulaMarkup(displayMarkup),
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
            label: .system(symbol),
            intent: .action(action),
            size: accent ? .wide : .normal,
            accessibilityLabel: accessibilityLabel
        )
    }
}
