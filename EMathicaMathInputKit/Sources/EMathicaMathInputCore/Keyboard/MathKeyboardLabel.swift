import Foundation

public enum MathKeyboardLabelDescriptor: Equatable, Sendable {
    case text(String)
    case symbol(markup: String, fallback: String)
    case formula(markup: String, fallback: String)
    case systemIcon(String)
}

public typealias MathKeyboardKeyLabel = MathKeyboardLabelDescriptor

public extension MathKeyboardLabelDescriptor {
    var staticMarkup: String? {
        switch self {
        case .symbol(let markup, _), .formula(let markup, _):
            return markup
        case .text, .systemIcon:
            return nil
        }
    }

    var fallbackText: String {
        switch self {
        case .text(let text):
            return text
        case .symbol(_, let fallback), .formula(_, let fallback):
            return fallback
        case .systemIcon(let systemName):
            return systemName
        }
    }

    var containsEditingControlMarkup: Bool {
        guard let markup = staticMarkup else { return false }
        return markup.contains(#"\placeholder"#) || markup.contains(#"\cursor"#)
    }
}

public enum MathKeyboardKeySize: Equatable, Sendable {
    case normal
    case wide
    case flexible(Double)
}
