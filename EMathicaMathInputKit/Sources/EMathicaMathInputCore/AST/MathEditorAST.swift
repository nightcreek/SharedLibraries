import Foundation

public indirect enum MathNode: Hashable, Codable {
    case sequence([MathNode])
    case character(String)
    case symbol(String)
    case operatorSymbol(String)
    case placeholder
    case template(TemplateNode)
}

public struct TemplateNode: Hashable, Codable {
    public var kind: TemplateKind
    public var fields: [TemplateField]

    public init(kind: TemplateKind, fields: [TemplateField]) {
        self.kind = kind
        self.fields = fields
    }

    public func field(_ id: FieldID) -> MathNode? {
        fields.first(where: { $0.id == id })?.node
    }
}

public struct TemplateField: Hashable, Codable {
    public init(id: FieldID, node: MathNode) { self.id = id; self.node = node }
    public var id: FieldID
    public var node: MathNode
}

public enum TemplateKind: Hashable, Codable, Sendable {
    case fraction
    case sqrt
    case nthRoot
    case superscript
    case subscriptTemplate
    case subscriptSuperscript
    case parentheses
    case brackets
    case braces
    case absoluteValue
    case vector
    case overline
    case hat
    case sin
    case cos
    case tan
    case ln
    case exp
    case log
    case limit
    case sum
    case product
    case integral
    case matrix(rows: Int, cols: Int)
    case cases(rows: Int)
    case piecewise(rows: Int)
    case parametricEquation2D
    case parametricEquation3D
}

public enum FieldID: Hashable, Codable {
    case numerator
    case denominator
    case radicand
    case rootIndex
    case base
    case exponent
    case subscriptField
    case content
    case argument
    case lowerBound
    case upperBound
    case integrand
    case variable
    case target
    case expression
    case rowExpression(Int)
    case rowCondition(Int)
    case matrixCell(row: Int, col: Int)
    case parametricExpression(Int)
    case parametricRange
}

public extension MathNode {
    public static var emptySequence: MathNode { .sequence([]) }

    public var isEmptyForEditing: Bool {
        switch self {
        case .placeholder:
            return true
        case .sequence(let nodes):
            return nodes.isEmpty || nodes.allSatisfy(\.isEmptyForEditing)
        case .template(let template):
            return template.fields.allSatisfy { $0.node.isEmptyForEditing }
        default:
            return false
        }
    }

    public var debugTree: String {
        switch self {
        case .sequence(let nodes):
            return "sequence([\n\(nodes.map { $0.debugTree.indented(2) }.joined(separator: ",\n"))\n])"
        case .character(let value):
            return "character(\"\(value)\")"
        case .symbol(let value):
            return "symbol(\"\(value)\")"
        case .operatorSymbol(let value):
            return "operator(\"\(value)\")"
        case .placeholder:
            return "placeholder"
        case .template(let template):
            let fields = template.fields.map { field in
                "\(field.id): \(field.node.debugTree)"
            }.joined(separator: ", ")
            return "template(\(template.kind), {\(fields)})"
        }
    }
}

private extension String {
    public func indented(_ spaces: Int) -> String {
        let prefix = String(repeating: " ", count: spaces)
        return split(separator: "\n", omittingEmptySubsequences: false)
            .map { prefix + $0 }
            .joined(separator: "\n")
    }
}
