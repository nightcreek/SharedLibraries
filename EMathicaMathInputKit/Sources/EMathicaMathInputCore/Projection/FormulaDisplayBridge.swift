import EMathicaFormulaDisplayCore
import Foundation

public enum FormulaDisplayBridge {
    public static func projectionSnapshot(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayProjectionSnapshot {
        MathInputArchitectureInvariants.validateDisplayProjectionInput(
            source: source,
            cursor: cursor
        )

        var insertionCursors: [FormulaInsertionID: EditorCursor] = [:]
        let root = buildNode(
            source,
            path: [],
            cursor: cursor?.editorCursor,
            includesInsertionMarkers: includesInsertionMarkers,
            insertionCursors: &insertionCursors
        )
        return FormulaDisplayProjectionSnapshot(
            document: FormulaDisplayDocument(root: root),
            insertionCursors: insertionCursors
        )
    }

    public static func document(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayDocument {
        projectionSnapshot(
            source: source,
            cursor: cursor,
            includesInsertionMarkers: includesInsertionMarkers
        ).document
    }

    public static func markup(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayMarkup {
        FormulaDisplayMarkup(
            rawValue: FormulaDisplayDocumentSerializer.serialize(
                document(
                    source: source,
                    cursor: cursor,
                    includesInsertionMarkers: includesInsertionMarkers
                )
            )
        )
    }

    private static func buildNode(
        _ formula: MathFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?,
        includesInsertionMarkers: Bool,
        insertionCursors: inout [FormulaInsertionID: EditorCursor]
    ) -> FormulaDisplayNode {
        switch formula {
        case .sequence(let items):
            return .sequence(
                buildSequence(
                    items,
                    path: path,
                    cursor: cursor,
                    includesInsertionMarkers: includesInsertionMarkers,
                    insertionCursors: &insertionCursors
                )
            )
        case .symbol(let value):
            return .text(value, role: .symbol)
        case .number(let value):
            return .text(value, role: .number)
        case .operatorSymbol(let value):
            return .operatorSymbol(value)
        case .rawLatex(let value):
            return .raw(value)
        case .function(let function):
            let arguments = function.arguments.enumerated().map { index, argument in
                buildFieldNode(
                    argument,
                    path: path + [.templateField(functionFieldID(for: function, argumentIndex: index))],
                    cursor: cursor,
                    includesInsertionMarkers: includesInsertionMarkers,
                    insertionCursors: &insertionCursors
                )
            }
            return .function(name: function.name, arguments: arguments)
        case .template(let template):
            return buildTemplate(
                template,
                path: path,
                cursor: cursor,
                includesInsertionMarkers: includesInsertionMarkers,
                insertionCursors: &insertionCursors
            )
        }
    }

    private static func buildSequence(
        _ items: [MathFormula],
        path: [EditorPathComponent],
        cursor: EditorCursor?,
        includesInsertionMarkers: Bool,
        insertionCursors: inout [FormulaInsertionID: EditorCursor]
    ) -> [FormulaDisplayNode] {
        if items.isEmpty {
            var nodes = [FormulaDisplayNode]()
            if includesInsertionMarkers {
                nodes.append(
                    insertionToken(
                        path: path,
                        offset: 0,
                        totalCount: 0,
                        insertionCursors: &insertionCursors
                    )
                )
            }
            if shouldInsertCursor(path: path, offset: 0, cursor: cursor) {
                nodes.append(cursorToken(path: path, offset: 0))
            }
            nodes.append(placeholderToken(path: path))
            return nodes
        }

        var nodes = [FormulaDisplayNode]()
        if includesInsertionMarkers {
            nodes.append(
                insertionToken(
                    path: path,
                    offset: 0,
                    totalCount: items.count,
                    insertionCursors: &insertionCursors
                )
            )
        }
        if shouldInsertCursor(path: path, offset: 0, cursor: cursor) {
            nodes.append(cursorToken(path: path, offset: 0))
        }

        for (index, item) in items.enumerated() {
            nodes.append(
                buildNode(
                    item,
                    path: path + [.sequenceIndex(index)],
                    cursor: cursor,
                    includesInsertionMarkers: includesInsertionMarkers,
                    insertionCursors: &insertionCursors
                )
            )
            if includesInsertionMarkers {
                nodes.append(
                    insertionToken(
                        path: path,
                        offset: index + 1,
                        totalCount: items.count,
                        insertionCursors: &insertionCursors
                    )
                )
            }
            if shouldInsertCursor(path: path, offset: index + 1, cursor: cursor) {
                nodes.append(cursorToken(path: path, offset: index + 1))
            }
        }
        return nodes
    }

    private static func buildTemplate(
        _ template: MathTemplateFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?,
        includesInsertionMarkers: Bool,
        insertionCursors: inout [FormulaInsertionID: EditorCursor]
    ) -> FormulaDisplayNode {
        switch template.kind {
        case .fraction:
            return .fraction(
                numerator: field(.numerator, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                denominator: field(.denominator, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .sqrt:
            return .sqrt(
                radicand: field(.radicand, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .nthRoot:
            return .nthRoot(
                index: field(.rootIndex, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                radicand: field(.radicand, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .superscript:
            return .superscript(
                base: field(.base, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                exponent: field(.exponent, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .subscript:
            return .subscript(
                base: field(.base, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                subscriptNode: field(.subscriptField, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .subscriptSuperscript:
            return .scriptPair(
                base: field(.base, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                subscriptNode: field(.subscriptField, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                superscriptNode: field(.exponent, at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .parentheses:
            return .parentheses(
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .brackets:
            return .brackets(
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .braces:
            return .braces(
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .absoluteValue:
            return .absoluteValue(
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .vector:
            return .accent(
                style: .vector,
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .overline:
            return .accent(
                style: .overline,
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .hat:
            return .accent(
                style: .hat,
                content: field(.content, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .piecewise(let rows):
            return .piecewise(
                rows: (0..<rows).map { row in
                    let baseIndex = row * 2
                    return .init(
                        expression: field(.rowExpression(row), at: baseIndex, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                        condition: field(.rowCondition(row), at: baseIndex + 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
                    )
                }
            )
        case .cases(let rows):
            return .cases(
                rows: (0..<rows).map { row in
                    .init(
                        cells: [
                            field(.rowExpression(row), at: row, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
                        ]
                    )
                }
            )
        case .parametric2D:
            return .parametric2D(
                x: field(.parametricExpression(0), at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                y: field(.parametricExpression(1), at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                range: field(.parametricRange, at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .parametric3D:
            return .parametric3D(
                x: field(.parametricExpression(0), at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                y: field(.parametricExpression(1), at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                z: field(.parametricExpression(2), at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .limit:
            return .limit(
                variable: field(.variable, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                target: field(.target, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                body: field(.expression, at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .sum:
            return .largeOperator(
                kind: .sum,
                variable: field(.variable, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                lowerBound: field(.lowerBound, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                upperBound: field(.upperBound, at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                body: field(.expression, at: 3, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .product:
            return .largeOperator(
                kind: .product,
                variable: field(.variable, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                lowerBound: field(.lowerBound, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                upperBound: field(.upperBound, at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                body: field(.expression, at: 3, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .integral:
            return .integral(
                lowerBound: field(.lowerBound, at: 0, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                upperBound: field(.upperBound, at: 1, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                integrand: field(.integrand, at: 2, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors),
                variable: field(.variable, at: 3, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
            )
        case .matrix(let rows, let cols):
            return .matrix(
                environment: .pmatrix,
                rows: (0..<rows).map { row in
                    .init(
                        cells: (0..<cols).map { col in
                            let index = row * cols + col
                            return field(.matrixCell(row: row, col: col), at: index, in: template, path: path, cursor: cursor, includesInsertionMarkers: includesInsertionMarkers, insertionCursors: &insertionCursors)
                        }
                    )
                }
            )
        }
    }

    private static func field(
        _ id: FieldID,
        at index: Int,
        in template: MathTemplateFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?,
        includesInsertionMarkers: Bool,
        insertionCursors: inout [FormulaInsertionID: EditorCursor]
    ) -> FormulaDisplayNode {
        let fieldPath = path + [.templateField(id)]
        guard template.fields.indices.contains(index) else {
            return .sequence(
                buildSequence(
                    [],
                    path: fieldPath,
                    cursor: cursor,
                    includesInsertionMarkers: includesInsertionMarkers,
                    insertionCursors: &insertionCursors
                )
            )
        }

        if includesInsertionMarkers {
            return buildFieldNode(
                template.fields[index],
                path: fieldPath,
                cursor: cursor,
                includesInsertionMarkers: true,
                insertionCursors: &insertionCursors
            )
        }

        return buildNode(
            template.fields[index],
            path: fieldPath,
            cursor: cursor,
            includesInsertionMarkers: false,
            insertionCursors: &insertionCursors
        )
    }

    private static func buildFieldNode(
        _ formula: MathFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?,
        includesInsertionMarkers: Bool,
        insertionCursors: inout [FormulaInsertionID: EditorCursor]
    ) -> FormulaDisplayNode {
        guard includesInsertionMarkers else {
            return buildNode(
                formula,
                path: path,
                cursor: cursor,
                includesInsertionMarkers: false,
                insertionCursors: &insertionCursors
            )
        }

        return .sequence(
            buildSequence(
                [formula],
                path: path,
                cursor: cursor,
                includesInsertionMarkers: true,
                insertionCursors: &insertionCursors
            )
        )
    }

    private static func shouldInsertCursor(
        path: [EditorPathComponent],
        offset: Int,
        cursor: EditorCursor?
    ) -> Bool {
        guard let cursor else { return false }
        return cursor.path == path && cursor.offset == offset
    }

    private static func functionFieldID(
        for function: MathFunctionFormula,
        argumentIndex: Int
    ) -> FieldID {
        if function.name == "log", function.arguments.count > 1 {
            return argumentIndex == 0 ? .base : .argument
        }
        return .argument
    }

    private static func placeholderToken(path: [EditorPathComponent]) -> FormulaDisplayNode {
        .placeholder(
            .init(
                id: "placeholder:\(pathKey(path))",
                sourcePath: sourcePath(path),
                fieldIdentity: fieldIdentity(path),
                kind: placeholderKind(path),
                widthPolicy: .quad
            )
        )
    }

    private static func cursorToken(
        path: [EditorPathComponent],
        offset: Int
    ) -> FormulaDisplayNode {
        .cursor(
            .init(
                id: "cursor:\(pathKey(path))@\(offset)",
                sourcePath: sourcePath(path),
                fieldIdentity: fieldIdentity(path),
                offset: offset,
                spacingPolicy: .medium
            )
        )
    }

    private static func insertionToken(
        path: [EditorPathComponent],
        offset: Int,
        totalCount: Int,
        insertionCursors: inout [FormulaInsertionID: EditorCursor]
    ) -> FormulaDisplayNode {
        let affinity: FormulaInsertionAffinity
        switch (offset, totalCount) {
        case (0, 0):
            affinity = .leading
        case (0, _):
            affinity = .leading
        case (_, let total) where offset == total:
            affinity = .trailing
        default:
            affinity = .interior
        }
        let id = FormulaInsertionID(
            sourcePath: sourcePath(path),
            offset: offset,
            affinity: affinity
        )
        insertionCursors[id] = EditorCursor(path: path, offset: offset)
        return .insertionMarker(
            .init(
                id: id,
                sourcePath: sourcePath(path),
                fieldIdentity: fieldIdentity(path),
                offset: offset,
                affinity: affinity,
                spacingPolicy: .zero
            )
        )
    }

    private static func sourcePath(_ path: [EditorPathComponent]) -> [String] {
        path.map { component in
            switch component {
            case .sequenceIndex(let index):
                return "sequence[\(index)]"
            case .templateField(let field):
                return "field.\(fieldKey(field))"
            }
        }
    }

    private static func pathKey(_ path: [EditorPathComponent]) -> String {
        if path.isEmpty {
            return "root"
        }
        return sourcePath(path).joined(separator: "/")
    }

    private static func fieldIdentity(_ path: [EditorPathComponent]) -> String? {
        guard case .templateField(let field)? = path.last else { return nil }
        return fieldKey(field)
    }

    private static func placeholderKind(_ path: [EditorPathComponent]) -> String {
        fieldIdentity(path) ?? "emptyField"
    }

    private static func fieldKey(_ field: FieldID) -> String {
        switch field {
        case .numerator:
            return "numerator"
        case .denominator:
            return "denominator"
        case .radicand:
            return "radicand"
        case .rootIndex:
            return "rootIndex"
        case .base:
            return "base"
        case .exponent:
            return "exponent"
        case .subscriptField:
            return "subscript"
        case .content:
            return "content"
        case .argument:
            return "argument"
        case .lowerBound:
            return "lowerBound"
        case .upperBound:
            return "upperBound"
        case .integrand:
            return "integrand"
        case .variable:
            return "variable"
        case .target:
            return "target"
        case .expression:
            return "expression"
        case .rowExpression(let index):
            return "rowExpression[\(index)]"
        case .rowCondition(let index):
            return "rowCondition[\(index)]"
        case .matrixCell(let row, let col):
            return "matrixCell[\(row),\(col)]"
        case .parametricExpression(let index):
            return "parametricExpression[\(index)]"
        case .parametricRange:
            return "parametricRange"
        }
    }
}
