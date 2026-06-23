public enum MathFunction: Codable, Hashable, Equatable, Sendable {
    case sin
    case cos
    case tan
    case asin
    case acos
    case atan
    case sinh
    case cosh
    case tanh
    case exp
    case ln
    case lg
    case log
    case logBase
    case sqrt
    case abs
    case floor
    case ceil
    case min
    case max
    case custom(String)
}

// MARK: - String-based lookup

extension MathFunction {
    /// Create a `MathFunction` from a string name.
    /// Returns `nil` for unknown function names.
    ///
    /// Mapping conventions:
    /// - `"ln"` and `"log"` both map to `.log` (natural logarithm in MathCore convention).
    ///   Use `"lg"` for base-10 logarithm.
    /// - `"asin"` and `"arcsin"` are accepted for inverse trig.
    /// - Unrecognized names return `nil`; callers should use `.custom(name)` explicitly.
    public init?(_ name: String) {
        switch name.lowercased() {
        case "sin": self = .sin
        case "cos": self = .cos
        case "tan": self = .tan
        case "asin", "arcsin": self = .asin
        case "acos", "arccos": self = .acos
        case "atan", "arctan": self = .atan
        case "sinh": self = .sinh
        case "cosh": self = .cosh
        case "tanh": self = .tanh
        case "exp": self = .exp
        case "ln": self = .ln
        case "lg": self = .lg
        case "log": self = .log
        case "sqrt": self = .sqrt
        case "abs": self = .abs
        case "floor": self = .floor
        case "ceil": self = .ceil
        default: return nil
        }
    }
}
