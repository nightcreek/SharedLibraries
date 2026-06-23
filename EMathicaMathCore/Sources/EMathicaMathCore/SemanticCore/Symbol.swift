public struct Symbol: Codable, Hashable, Equatable, Sendable {
    public var name: String
    public var role: SymbolRole
    public var namespace: SymbolNamespace?

    public init(
        name: String,
        role: SymbolRole = .unknown,
        namespace: SymbolNamespace? = nil
    ) {
        self.name = name
        self.role = role
        self.namespace = namespace
    }
}

public enum SymbolRole: String, Codable, Hashable, Equatable, Sendable {
    case variable
    case parameter
    case function
    case constant
    case objectName
    case unit
    case unknown
}

public enum SymbolNamespace: String, Codable, Hashable, Equatable, Sendable {
    case global
    case local
    case object
    case userDefined
    case system
    case plugin
}
