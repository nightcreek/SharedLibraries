public enum RelationOperator: String, Codable, Hashable, Equatable, Sendable {
    case equal
    case notEqual
    case less
    case lessOrEqual
    case greater
    case greaterOrEqual
    case approximatelyEqual
}
