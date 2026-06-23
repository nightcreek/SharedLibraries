public struct EvaluationEnvironment: Sendable {
    public var values: [Symbol: Double]

    public init(values: [Symbol: Double] = [:]) {
        self.values = values
    }

    public func value(for symbol: Symbol) -> Double? {
        if let exact = values[symbol] {
            return exact
        }
        return values.first(where: { $0.key.name == symbol.name })?.value
    }

    public static func variables(_ values: [String: Double]) -> EvaluationEnvironment {
        let mapped = Dictionary(
            uniqueKeysWithValues: values.map { (name, value) in
                (Symbol(name: name, role: .variable), value)
            }
        )
        return EvaluationEnvironment(values: mapped)
    }
}
