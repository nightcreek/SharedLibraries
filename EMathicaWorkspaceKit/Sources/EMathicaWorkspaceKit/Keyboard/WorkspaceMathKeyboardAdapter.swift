import EMathicaMathInputCore

enum WorkspaceMathKeyboardAdapter {
    static func rows(for panelID: String) -> [[KeyboardKey]] {
        guard let panel = MathKeyboardLayouts.standard.panels.first(where: { $0.id == panelID }) else {
            return []
        }
        return panel.rows.map { row in
            row.keys.compactMap { key in
                guard key.intent.keyboardAction != nil else { return nil }
                return KeyboardKey(coreKey: key)
            }
        }
    }

    static func legacyLabel(for key: EMathicaMathInputCore.MathKeyboardKey) -> (title: String, subtitle: String?) {
        switch key.id {
        case "numbers-superscript-square":
            return ("x²", "上标")
        case "numbers-superscript-generic":
            return ("xʸ", "指数")
        case "numbers-sqrt", "functions-sqrt":
            return ("√□", "根号")
        case "numbers-abs":
            return ("|□|", "绝对值")
        case "functions-abs":
            return ("|□|", "abs")
        case "functions-fraction":
            return ("□⁄□", "分数")
        case "functions-superscript":
            return ("xʸ", "上标")
        case "functions-subscript":
            return ("xₙ", "下标")
        case "functions-parametric-2d":
            return ("x(t),y(t)", "参数")
        case "functions-piecewise":
            return ("分段", "cases")
        case "functions-parentheses":
            return ("(□)", "括号")
        default:
            switch key.label {
            case .text(let text), .system(let text):
                return (text, nil)
            case .formulaMarkup(let markup):
                return (markup, nil)
            }
        }
    }

    static func isTemplate(_ key: EMathicaMathInputCore.MathKeyboardKey) -> Bool {
        switch key.intent {
        case .input(.template), .action(.insertTemplate):
            return true
        default:
            return false
        }
    }

    static func isAccent(_ key: EMathicaMathInputCore.MathKeyboardKey) -> Bool {
        switch key.id {
        case "numbers-eq", "numbers-submit", "functions-submit", "alphabet-submit", "symbols-submit":
            return true
        default:
            return false
        }
    }
}
