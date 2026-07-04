import Foundation

public struct HardwareKeyboardModifiers: OptionSet, Equatable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let shift = HardwareKeyboardModifiers(rawValue: 1 << 0)
    public static let command = HardwareKeyboardModifiers(rawValue: 1 << 1)
}

public struct HardwareKeyboardDescriptor: Equatable, Sendable {
    public var keyCode: Int?
    public var characters: String?
    public var charactersIgnoringModifiers: String?
    public var modifiers: HardwareKeyboardModifiers

    public init(
        keyCode: Int? = nil,
        characters: String? = nil,
        charactersIgnoringModifiers: String? = nil,
        modifiers: HardwareKeyboardModifiers = []
    ) {
        self.keyCode = keyCode
        self.characters = characters
        self.charactersIgnoringModifiers = charactersIgnoringModifiers
        self.modifiers = modifiers
    }
}

public struct HardwareKeyboardSemanticMapper: Sendable {
    public init() {}

    public func intent(for input: HardwareKeyboardDescriptor) -> MathKeyboardIntent? {
        if input.modifiers.contains(.command) {
            return nil
        }

        if input.keyCode == 35, input.modifiers.contains(.shift) {
            return .input(.template(.superscript))
        }
        if input.keyCode == 40 {
            return .action(.submit)
        }
        if input.keyCode == 42 {
            return .action(.deleteBackward)
        }
        if input.keyCode == 76 {
            return .action(.deleteForward)
        }
        if input.keyCode == 43 {
            return input.modifiers.contains(.shift) ? .action(.shiftTab) : .action(.tab)
        }
        if input.keyCode == 80 {
            return .action(.moveLeft)
        }
        if input.keyCode == 79 {
            return .action(.moveRight)
        }
        if input.keyCode == 82 {
            return .action(.moveUp)
        }
        if input.keyCode == 81 {
            return .action(.moveDown)
        }
        if input.keyCode == 41 {
            return .action(.cancel)
        }

        let raw = input.characters ?? ""
        let fallback = input.charactersIgnoringModifiers ?? ""
        let value = raw.isEmpty ? fallback : raw

        if value == "^" {
            return .input(.template(.superscript))
        }
        if value.isEmpty {
            return nil
        }

        if ["+", "-", "=", "*", "/", "<", ">", ","].contains(value) {
            return .input(.op(value))
        }
        if value.allSatisfy(\.isNumber) {
            return .input(.number(value))
        }
        return .input(.char(value))
    }
}

