import Foundation

enum MathFormulaProjection {
    static func project(_ node: MathNode) -> MathFormula {
        switch node {
        case .sequence(let nodes):
            return .sequence(projectSequence(nodes))
        case .character(let value):
            return projectCharacterFragment(value)
        case .symbol(let value):
            return .symbol(value)
        case .operatorSymbol(let value):
            return .operatorSymbol(value)
        case .placeholder:
            return .sequence([])
        case .template(let template):
            return projectTemplate(template)
        }
    }

    private static func projectSequence(_ nodes: [MathNode]) -> [MathFormula] {
        var result: [MathFormula] = []
        var numericBuffer = ""

        func flushNumericBuffer() {
            guard !numericBuffer.isEmpty else { return }
            if numericBuffer == "." {
                result.append(.rawLatex(numericBuffer))
            } else {
                result.append(.number(numericBuffer))
            }
            numericBuffer.removeAll(keepingCapacity: true)
        }

        for node in nodes {
            switch node {
            case .character(let value):
                consumeCharacterFragment(value, numericBuffer: &numericBuffer, result: &result)
            case .placeholder:
                flushNumericBuffer()
                continue
            default:
                flushNumericBuffer()
                result.append(project(node))
            }
        }

        flushNumericBuffer()
        return result
    }

    private static func consumeCharacterFragment(
        _ value: String,
        numericBuffer: inout String,
        result: inout [MathFormula]
    ) {
        for character in value {
            let scalarString = String(character)
            if isNumberFragmentCharacter(character) {
                numericBuffer.append(character)
                continue
            }

            if !numericBuffer.isEmpty {
                if numericBuffer == "." {
                    result.append(.rawLatex(numericBuffer))
                } else {
                    result.append(.number(numericBuffer))
                }
                numericBuffer.removeAll(keepingCapacity: true)
            }

            if isSymbolCharacter(character) {
                result.append(.symbol(scalarString))
            } else {
                result.append(.rawLatex(scalarString))
            }
        }
    }

    private static func projectCharacterFragment(_ value: String) -> MathFormula {
        var formulas: [MathFormula] = []
        var numericBuffer = ""
        consumeCharacterFragment(value, numericBuffer: &numericBuffer, result: &formulas)
        if !numericBuffer.isEmpty {
            if numericBuffer == "." {
                formulas.append(.rawLatex(numericBuffer))
            } else {
                formulas.append(.number(numericBuffer))
            }
        }
        if formulas.count == 1, let single = formulas.first {
            return single
        }
        return .sequence(formulas)
    }

    private static func projectTemplate(_ template: TemplateNode) -> MathFormula {
        switch template.kind {
        case .fraction:
            return .template(
                MathTemplateFormula(
                    kind: .fraction,
                    fields: [
                        projectField(template.field(.numerator)),
                        projectField(template.field(.denominator))
                    ]
                )
            )
        case .sqrt:
            return .template(
                MathTemplateFormula(
                    kind: .sqrt,
                    fields: [
                        projectField(template.field(.radicand))
                    ]
                )
            )
        case .superscript:
            return .template(
                MathTemplateFormula(
                    kind: .superscript,
                    fields: [
                        projectField(template.field(.base)),
                        projectField(template.field(.exponent))
                    ]
                )
            )
        case .subscriptTemplate:
            return .template(
                MathTemplateFormula(
                    kind: .subscript,
                    fields: [
                        projectField(template.field(.base)),
                        projectField(template.field(.subscriptField))
                    ]
                )
            )
        case .parentheses:
            return .template(
                MathTemplateFormula(
                    kind: .parentheses,
                    fields: [
                        projectField(template.field(.content))
                    ]
                )
            )
        case .absoluteValue:
            return .template(
                MathTemplateFormula(
                    kind: .absoluteValue,
                    fields: [
                        projectField(template.field(.content))
                    ]
                )
            )
        case .sin, .cos, .tan, .ln, .exp:
            return .function(
                MathFunctionFormula(
                    name: functionName(for: template.kind),
                    arguments: [projectField(template.field(.argument))]
                )
            )
        case .log:
            let base = projectField(template.field(.base))
            let argument = projectField(template.field(.argument))
            let arguments = isVisiblyEmpty(base) ? [argument] : [base, argument]
            return .function(
                MathFunctionFormula(
                    name: "log",
                    arguments: arguments
                )
            )
        default:
            return .rawLatex(LatexMathRenderer().renderLatex(.template(template), editing: false))
        }
    }

    private static func functionName(for kind: TemplateKind) -> String {
        switch kind {
        case .sin: return "sin"
        case .cos: return "cos"
        case .tan: return "tan"
        case .ln: return "ln"
        case .exp: return "exp"
        case .log: return "log"
        default:
            return "unknown"
        }
    }

    private static func projectField(_ node: MathNode?) -> MathFormula {
        guard let node else {
            return .sequence([])
        }
        if node.isEmptyForEditing {
            return .sequence([])
        }
        return project(node)
    }

    private static func isVisiblyEmpty(_ formula: MathFormula) -> Bool {
        switch formula {
        case .sequence(let items):
            return items.isEmpty || items.allSatisfy(isVisiblyEmpty)
        case .rawLatex(let value):
            return value.isEmpty
        default:
            return false
        }
    }

    private static func isNumberFragmentCharacter(_ character: Character) -> Bool {
        character.isNumber || character == "."
    }

    private static func isSymbolCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }
}
