import Foundation

public enum FormulaKeyboardEditingIntent: Hashable, Equatable, Codable, Sendable {
    case deleteBackward
    case deleteForward
    case submit
    case cancel
}
