import EMathicaMathInputCore

@available(*, deprecated, message: "Use MathKeyboardKeyLabel and MathInputKeyboardView instead.")
public struct KeyboardKey: Identifiable, Hashable, Equatable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var action: KeyboardAction
    public var isTemplate: Bool
    public var isAccent: Bool

    public init(
        id: String,
        title: String,
        subtitle: String?,
        action: KeyboardAction,
        isTemplate: Bool,
        isAccent: Bool
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isTemplate = isTemplate
        self.isAccent = isAccent
    }

    public static func text(_ value: String) -> KeyboardKey {
        KeyboardKey(
            id: "text:\(value)",
            title: value,
            subtitle: nil,
            action: .insertCharacter(value),
            isTemplate: false,
            isAccent: false
        )
    }

    public static func symbol(_ title: String, raw: String) -> KeyboardKey {
        KeyboardKey(
            id: "symbol:\(raw)",
            title: title,
            subtitle: nil,
            action: .insertSymbol(raw),
            isTemplate: false,
            isAccent: false
        )
    }

    public static func op(_ title: String, raw: String, accent: Bool = false) -> KeyboardKey {
        KeyboardKey(
            id: "op:\(raw):\(title)",
            title: title,
            subtitle: nil,
            action: .insertOperator(raw),
            isTemplate: false,
            isAccent: accent
        )
    }

    public static func template(
        _ title: String,
        subtitle: String,
        kind: TemplateKind,
        accent: Bool = false
    ) -> KeyboardKey {
        KeyboardKey(
            id: "tpl:\(title)",
            title: title,
            subtitle: subtitle,
            action: .insertTemplate(kind),
            isTemplate: true,
            isAccent: accent
        )
    }

    public static func function(_ title: String) -> KeyboardKey {
        KeyboardKey(
            id: "fn:\(title)",
            title: title,
            subtitle: nil,
            action: .insertFunction(title),
            isTemplate: false,
            isAccent: false
        )
    }

    public static func command(_ title: String, action: KeyboardAction, accent: Bool = false) -> KeyboardKey {
        KeyboardKey(
            id: "cmd:\(title)",
            title: title,
            subtitle: nil,
            action: action,
            isTemplate: false,
            isAccent: accent
        )
    }

    init(coreKey: EMathicaMathInputCore.MathKeyboardKey) {
        let labelParts = WorkspaceMathKeyboardAdapter.legacyLabel(for: coreKey)
        self.id = coreKey.id
        self.title = labelParts.title
        self.subtitle = labelParts.subtitle
        self.action = coreKey.intent.keyboardAction ?? .submit
        self.isTemplate = WorkspaceMathKeyboardAdapter.isTemplate(coreKey)
        self.isAccent = WorkspaceMathKeyboardAdapter.isAccent(coreKey)
    }
}
