import Foundation

public indirect enum MathFormula: Hashable {
    case sequence([MathFormula])
    case symbol(String)
    case number(String)
    case operatorSymbol(String)
    case function(MathFunctionFormula)
    case template(MathTemplateFormula)
    case rawLatex(String)
}

public struct MathFunctionFormula: Hashable {
    public var name: String
    public var arguments: [MathFormula]

    public init(name: String, arguments: [MathFormula]) {
        self.name = name
        self.arguments = arguments
    }
}

public struct MathTemplateFormula: Hashable {
    public var kind: MathTemplateKind
    public var fields: [MathFormula]

    public init(kind: MathTemplateKind, fields: [MathFormula]) {
        self.kind = kind
        self.fields = fields
    }
}

public enum MathTemplateKind: String, Hashable {
    case fraction
    case sqrt
    case superscript
    case `subscript`
    case parentheses
    case absoluteValue
}

public struct FormulaDisplayMarkup: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}
