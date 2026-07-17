import Foundation

/// One-way snapshot projection from editor AST into the public structural protocol.
///
/// Editor Dominance Rule:
/// - `MathNode` / `EditorState` remain the only mutable editing structures.
/// - projection is deterministic and one-way.
/// - projected `MathFormula` values must never be fed back as an editing surface.
public enum MathFormulaProjection {
    public static func snapshot(from root: MathNode) -> MathFormula {
        let snapshot = project(root)
        MathInputArchitectureInvariants.validateProjectionSnapshot(snapshot)
        return snapshot
    }

    @available(*, unavailable, message: "Projection is one-way only. MathFormula must not be converted back into mutable editor state.")
    public static func editorState(from formula: MathFormula) -> EditorState {
        fatalError("Unavailable")
    }

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
            return templateFormula(.fraction, fields: [.numerator, .denominator], template: template)
        case .sqrt:
            return templateFormula(.sqrt, fields: [.radicand], template: template)
        case .nthRoot:
            return templateFormula(.nthRoot, fields: [.rootIndex, .radicand], template: template)
        case .superscript:
            return templateFormula(.superscript, fields: [.base, .exponent], template: template)
        case .subscriptTemplate:
            return templateFormula(.subscript, fields: [.base, .subscriptField], template: template)
        case .subscriptSuperscript:
            return templateFormula(.subscriptSuperscript, fields: [.base, .subscriptField, .exponent], template: template)
        case .parentheses:
            return templateFormula(.parentheses, fields: [.content], template: template)
        case .brackets:
            return templateFormula(.brackets, fields: [.content], template: template)
        case .braces:
            return templateFormula(.braces, fields: [.content], template: template)
        case .absoluteValue:
            return templateFormula(.absoluteValue, fields: [.content], template: template)
        case .vector:
            return templateFormula(.vector, fields: [.content], template: template)
        case .overline:
            return templateFormula(.overline, fields: [.content], template: template)
        case .hat:
            return templateFormula(.hat, fields: [.content], template: template)
        case .piecewise(let rows):
            return .template(
                MathTemplateFormula(
                    kind: .piecewise(rows: rows),
                    fields: piecewiseFields(rows: rows, template: template)
                )
            )
        case .cases(let rows):
            return .template(
                MathTemplateFormula(
                    kind: .cases(rows: rows),
                    fields: (0..<rows).map { projectField(template.field(.rowExpression($0))) }
                )
            )
        case .parametricEquation2D:
            return .template(
                MathTemplateFormula(
                    kind: .parametric2D,
                    fields: [
                        projectField(template.field(.parametricExpression(0))),
                        projectField(template.field(.parametricExpression(1))),
                        projectField(template.field(.parametricRange))
                    ]
                )
            )
        case .parametricEquation3D:
            return .template(
                MathTemplateFormula(
                    kind: .parametric3D,
                    fields: [
                        projectField(template.field(.parametricExpression(0))),
                        projectField(template.field(.parametricExpression(1))),
                        projectField(template.field(.parametricExpression(2)))
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
        case .limit:
            return templateFormula(.limit, fields: [.variable, .target, .expression], template: template)
        case .sum:
            return templateFormula(.sum, fields: [.variable, .lowerBound, .upperBound, .expression], template: template)
        case .product:
            return templateFormula(.product, fields: [.variable, .lowerBound, .upperBound, .expression], template: template)
        case .integral:
            return templateFormula(.integral, fields: [.lowerBound, .upperBound, .integrand, .variable], template: template)
        case .matrix(let rows, let cols):
            let fields = (0..<rows).flatMap { row in
                (0..<cols).map { col in projectField(template.field(.matrixCell(row: row, col: col))) }
            }
            return .template(
                MathTemplateFormula(
                    kind: .matrix(rows: rows, cols: cols),
                    fields: fields
                )
            )
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
        switch node {
        case .template(let template):
            return projectTemplate(template)
        case .sequence(let nodes):
            return projectFieldSequence(nodes)
        case .placeholder:
            return .sequence([])
        case .character, .symbol, .operatorSymbol:
            return project(node)
        }
    }

    private static func projectFieldSequence(_ nodes: [MathNode]) -> MathFormula {
        let projected = projectSequence(nodes)
        guard !projected.isEmpty else {
            return .sequence([])
        }
        if projected.count == 1, let single = projected.first, shouldUnwrapSingletonFieldFormula(single) {
            return single
        }
        return .sequence(projected)
    }

    private static func shouldUnwrapSingletonFieldFormula(_ formula: MathFormula) -> Bool {
        switch formula {
        case .template, .function:
            return true
        default:
            return false
        }
    }

    private static func templateFormula(
        _ kind: MathTemplateKind,
        fields: [FieldID],
        template: TemplateNode
    ) -> MathFormula {
        .template(
            MathTemplateFormula(
                kind: kind,
                fields: fields.map { projectField(template.field($0)) }
            )
        )
    }

    private static func piecewiseFields(rows: Int, template: TemplateNode) -> [MathFormula] {
        (0..<rows).flatMap { row in
            [
                projectField(template.field(.rowExpression(row))),
                projectField(template.field(.rowCondition(row)))
            ]
        }
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

    private static func fallbackRawLatex(for template: TemplateNode) -> MathFormula {
        .rawLatex(LatexMathRenderer().renderLatex(.template(template), editing: false))
    }

    private static func isNumberFragmentCharacter(_ character: Character) -> Bool {
        character.isNumber || character == "."
    }

    private static func isSymbolCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }
}
