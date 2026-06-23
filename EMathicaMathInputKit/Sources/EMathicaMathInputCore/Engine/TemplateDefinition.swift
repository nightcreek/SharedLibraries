import Foundation

public struct TemplateDefinition {
    public let kind: TemplateKind
    public let fields: [FieldID]
    public let initialField: FieldID
    public let tabOrder: [FieldID]
    public let arrowNavigation: [FieldID: ArrowTargets]
}

public struct ArrowTargets {
    public var up: FieldID?
    public var down: FieldID?
    public var left: FieldID?
    public var right: FieldID?
}

public enum TemplateDefinitionRegistry {
    public static func definition(for kind: TemplateKind) -> TemplateDefinition {
        switch kind {
        case .fraction:
            return TemplateDefinition(
                kind: .fraction,
                fields: [.numerator, .denominator],
                initialField: .numerator,
                tabOrder: [.numerator, .denominator],
                arrowNavigation: [
                    .numerator: ArrowTargets(up: nil, down: .denominator, left: nil, right: .denominator),
                    .denominator: ArrowTargets(up: .numerator, down: nil, left: .numerator, right: nil)
                ]
            )
        case .sqrt:
            return TemplateDefinition(kind: .sqrt, fields: [.radicand], initialField: .radicand, tabOrder: [.radicand], arrowNavigation: [:])
        case .nthRoot:
            return TemplateDefinition(kind: .nthRoot, fields: [.rootIndex, .radicand], initialField: .rootIndex, tabOrder: [.rootIndex, .radicand], arrowNavigation: [:])
        case .superscript:
            return TemplateDefinition(
                kind: .superscript,
                fields: [.base, .exponent],
                initialField: .exponent,
                tabOrder: [.base, .exponent],
                arrowNavigation: [
                    .base: ArrowTargets(up: .exponent, down: nil, left: nil, right: .exponent),
                    .exponent: ArrowTargets(up: nil, down: .base, left: .base, right: nil)
                ]
            )
        case .subscriptTemplate:
            return TemplateDefinition(
                kind: .subscriptTemplate,
                fields: [.base, .subscriptField],
                initialField: .subscriptField,
                tabOrder: [.base, .subscriptField],
                arrowNavigation: [
                    .base: ArrowTargets(up: nil, down: .subscriptField, left: nil, right: .subscriptField),
                    .subscriptField: ArrowTargets(up: .base, down: nil, left: .base, right: nil)
                ]
            )
        case .parentheses, .brackets, .braces, .absoluteValue, .vector, .overline, .hat:
            return TemplateDefinition(kind: kind, fields: [.content], initialField: .content, tabOrder: [.content], arrowNavigation: [:])
        case .sin, .cos, .tan, .ln, .exp:
            return TemplateDefinition(
                kind: kind,
                fields: [.argument],
                initialField: .argument,
                tabOrder: [.argument],
                arrowNavigation: [
                    .argument: ArrowTargets(up: nil, down: nil, left: nil, right: nil)
                ]
            )
        case .log:
            return TemplateDefinition(kind: .log, fields: [.base, .argument], initialField: .argument, tabOrder: [.base, .argument], arrowNavigation: [:])
        case .limit:
            return TemplateDefinition(kind: .limit, fields: [.variable, .target, .expression], initialField: .variable, tabOrder: [.variable, .target, .expression], arrowNavigation: [:])
        case .sum, .product:
            return TemplateDefinition(kind: kind, fields: [.variable, .lowerBound, .upperBound, .expression], initialField: .variable, tabOrder: [.variable, .lowerBound, .upperBound, .expression], arrowNavigation: [:])
        case .integral:
            return TemplateDefinition(kind: .integral, fields: [.lowerBound, .upperBound, .integrand, .variable], initialField: .lowerBound, tabOrder: [.lowerBound, .upperBound, .integrand, .variable], arrowNavigation: [:])
        case .matrix(let rows, let cols):
            let fields = matrixFields(rows: rows, cols: cols)
            return TemplateDefinition(kind: .matrix(rows: rows, cols: cols), fields: fields, initialField: fields.first ?? .content, tabOrder: fields, arrowNavigation: matrixArrows(rows: rows, cols: cols))
        case .cases(let rows):
            let fields = (0..<rows).map(FieldID.rowExpression)
            return TemplateDefinition(kind: .cases(rows: rows), fields: fields, initialField: fields.first ?? .content, tabOrder: fields, arrowNavigation: [:])
        case .piecewise(let rows):
            let fields = piecewiseFields(rows: rows)
            return TemplateDefinition(kind: .piecewise(rows: rows), fields: fields, initialField: .rowExpression(0), tabOrder: fields, arrowNavigation: piecewiseArrows(rows: rows))
        case .parametricEquation2D:
            return TemplateDefinition(
                kind: .parametricEquation2D,
                fields: [.parametricExpression(0), .parametricExpression(1), .parametricRange],
                initialField: .parametricExpression(0),
                tabOrder: [.parametricExpression(0), .parametricExpression(1), .parametricRange],
                arrowNavigation: [
                    .parametricExpression(0): ArrowTargets(up: nil, down: .parametricExpression(1), left: nil, right: .parametricExpression(1)),
                    .parametricExpression(1): ArrowTargets(up: .parametricExpression(0), down: .parametricRange, left: .parametricExpression(0), right: .parametricRange),
                    .parametricRange: ArrowTargets(up: .parametricExpression(1), down: nil, left: .parametricExpression(1), right: nil)
                ]
            )
        case .parametricEquation3D:
            return TemplateDefinition(kind: .parametricEquation3D, fields: [.parametricExpression(0), .parametricExpression(1), .parametricExpression(2)], initialField: .parametricExpression(0), tabOrder: [.parametricExpression(0), .parametricExpression(1), .parametricExpression(2)], arrowNavigation: [.parametricExpression(0): ArrowTargets(up: nil, down: .parametricExpression(1), left: nil, right: nil), .parametricExpression(1): ArrowTargets(up: .parametricExpression(0), down: .parametricExpression(2), left: nil, right: nil), .parametricExpression(2): ArrowTargets(up: .parametricExpression(1), down: nil, left: nil, right: nil)])
        case .subscriptSuperscript:
            return TemplateDefinition(kind: .subscriptSuperscript, fields: [.base, .subscriptField, .exponent], initialField: .subscriptField, tabOrder: [.subscriptField, .exponent], arrowNavigation: [.subscriptField: ArrowTargets(up: .exponent, down: nil, left: nil, right: nil), .exponent: ArrowTargets(up: nil, down: .subscriptField, left: nil, right: nil)])
        }
    }

    private static func matrixFields(rows: Int, cols: Int) -> [FieldID] {
        var fields: [FieldID] = []
        for row in 0..<rows {
            for col in 0..<cols {
                fields.append(.matrixCell(row: row, col: col))
            }
        }
        return fields
    }

    private static func piecewiseFields(rows: Int) -> [FieldID] {
        var fields: [FieldID] = []
        for row in 0..<rows {
            fields.append(.rowExpression(row))
            fields.append(.rowCondition(row))
        }
        return fields
    }

    private static func matrixArrows(rows: Int, cols: Int) -> [FieldID: ArrowTargets] {
        var map: [FieldID: ArrowTargets] = [:]
        for row in 0..<rows {
            for col in 0..<cols {
                let id: FieldID = .matrixCell(row: row, col: col)
                map[id] = ArrowTargets(
                    up: row > 0 ? .matrixCell(row: row - 1, col: col) : nil,
                    down: row + 1 < rows ? .matrixCell(row: row + 1, col: col) : nil,
                    left: col > 0 ? .matrixCell(row: row, col: col - 1) : nil,
                    right: col + 1 < cols ? .matrixCell(row: row, col: col + 1) : nil
                )
            }
        }
        return map
    }

    private static func piecewiseArrows(rows: Int) -> [FieldID: ArrowTargets] {
        var map: [FieldID: ArrowTargets] = [:]
        for row in 0..<rows {
            map[.rowExpression(row)] = ArrowTargets(
                up: row > 0 ? .rowExpression(row - 1) : nil,
                down: row + 1 < rows ? .rowExpression(row + 1) : nil,
                left: nil,
                right: .rowCondition(row)
            )
            map[.rowCondition(row)] = ArrowTargets(
                up: row > 0 ? .rowCondition(row - 1) : nil,
                down: row + 1 < rows ? .rowCondition(row + 1) : nil,
                left: .rowExpression(row),
                right: row + 1 < rows ? .rowExpression(row + 1) : nil
            )
        }
        return map
    }
}
