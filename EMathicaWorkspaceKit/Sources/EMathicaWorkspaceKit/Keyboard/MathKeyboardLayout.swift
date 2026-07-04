import EMathicaMathInputCore

public enum MathKeyboardTab: String, CaseIterable, Identifiable {
    case numbers
    case functions
    case alphabet
    case symbols

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .numbers: return "123"
        case .functions: return "f(x)"
        case .alphabet: return "ABC"
        case .symbols: return "符号"
        }
    }

    public var rows: [[KeyboardKey]] {
        switch self {
        case .numbers:
            return WorkspaceMathKeyboardAdapter.rows(for: id)
        case .functions:
            return WorkspaceMathKeyboardAdapter.rows(for: id)
        case .alphabet:
            return WorkspaceMathKeyboardAdapter.rows(for: id)
        case .symbols:
            return WorkspaceMathKeyboardAdapter.rows(for: id)
        }
    }
}
