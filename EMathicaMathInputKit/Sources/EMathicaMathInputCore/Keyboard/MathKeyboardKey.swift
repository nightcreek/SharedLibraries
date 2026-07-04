import Foundation

public enum MathKeyboardIntent: Equatable, Sendable {
    case input(MathInputToken)
    case action(KeyboardAction)
    case none
}

public struct MathKeyboardKey: Equatable, Sendable, Identifiable {
    public var id: String
    public var label: MathKeyboardKeyLabel
    public var intent: MathKeyboardIntent
    public var size: MathKeyboardKeySize
    public var accessibilityLabel: String?

    public init(
        id: String,
        label: MathKeyboardKeyLabel,
        intent: MathKeyboardIntent,
        size: MathKeyboardKeySize = .normal,
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.label = label
        self.intent = intent
        self.size = size
        self.accessibilityLabel = accessibilityLabel
    }
}

public extension MathKeyboardIntent {
    var keyboardAction: KeyboardAction? {
        switch self {
        case .action(let action):
            return action
        case .input(let token):
            switch token {
            case .char(let value):
                return .insertCharacter(value)
            case .number(let value):
                return .insertCharacter(value)
            case .op(let value):
                return .insertOperator(value)
            case .function(let value):
                return .insertFunction(value)
            case .template(let value):
                switch value {
                case .fraction:
                    return .insertTemplate(.fraction)
                case .sqrt:
                    return .insertTemplate(.sqrt)
                case .superscript:
                    return .insertTemplate(.superscript)
                case .subscript:
                    return .insertTemplate(.subscriptTemplate)
                case .parentheses:
                    return .insertTemplate(.parentheses)
                case .absoluteValue:
                    return .insertTemplate(.absoluteValue)
                }
            case .control(let value):
                switch value {
                case .moveLeft:
                    return .moveLeft
                case .moveRight:
                    return .moveRight
                case .moveUp:
                    return .moveUp
                case .moveDown:
                    return .moveDown
                case .nextSlot:
                    return .tab
                case .previousSlot:
                    return .shiftTab
                case .deleteBackward:
                    return .deleteBackward
                case .deleteForward:
                    return .deleteForward
                case .submit:
                    return .submit
                case .cancel:
                    return .cancel
                case .undo, .redo:
                    return nil
                }
            }
        case .none:
            return nil
        }
    }
}

