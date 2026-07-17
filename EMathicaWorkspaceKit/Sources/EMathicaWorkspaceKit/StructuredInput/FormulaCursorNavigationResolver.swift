import EMathicaFormulaDisplayCore
import EMathicaMathInputCore
import Foundation

public enum FormulaCursorNavigationResolver {
    public static func resolve(
        action: KeyboardAction,
        editorState: EditorState
    ) -> EditorCursor? {
        switch action {
        case .moveLeft:
            return resolveLinearNavigation(direction: .left, editorState: editorState)
        case .moveRight:
            return resolveLinearNavigation(direction: .right, editorState: editorState)
        case .moveUp:
            return resolveStructuralNavigation(direction: .up, editorState: editorState)
        case .moveDown:
            return resolveStructuralNavigation(direction: .down, editorState: editorState)
        case .tab:
            return EMathicaWorkspaceKit.EditorCursorNavigator(root: editorState.root)
                .moveNextMajorSlot(from: editorState.cursor)
        case .shiftTab:
            return EMathicaWorkspaceKit.EditorCursorNavigator(root: editorState.root)
                .movePreviousMajorSlot(from: editorState.cursor)
        default:
            return nil
        }
    }

    private enum LinearDirection {
        case left
        case right
    }

    private enum StructuralDirection {
        case up
        case down
    }

    private static func resolveLinearNavigation(
        direction: LinearDirection,
        editorState: EditorState
    ) -> EditorCursor? {
        let projectionState = FormulaInputState(editorState: editorState)
        let projectionSnapshot = projectionState.displayProjectionSnapshot(includesInsertionMarkers: true)
        let orderedInsertionIDs = orderedInsertionIDs(in: projectionSnapshot.document.root)
        guard !orderedInsertionIDs.isEmpty else {
            return fallbackCursor(
                direction: direction,
                editorState: editorState
            )
        }

        let orderedIndices = Dictionary<FormulaInsertionID, Int>(
            uniqueKeysWithValues: orderedInsertionIDs.enumerated().map { ($0.element, $0.offset) }
        )
        let insertionIDsByCursor = Dictionary(
            grouping: projectionSnapshot.insertionCursors,
            by: { $0.value }
        )
        .mapValues { pairs in
            pairs.map(\.key).sorted {
                (orderedIndices[$0] ?? Int.max) < (orderedIndices[$1] ?? Int.max)
            }
        }

        guard let currentIDs = insertionIDsByCursor[editorState.cursor], !currentIDs.isEmpty else {
            return fallbackCursor(
                direction: direction,
                editorState: editorState
            )
        }

        let currentID = currentInsertionID(
            for: direction,
            currentIDs: currentIDs,
            orderedIndices: orderedIndices
        )
        guard let currentID, let currentIndex = orderedIndices[currentID] else {
            return fallbackCursor(
                direction: direction,
                editorState: editorState
            )
        }

        let targetIndex = direction == .left ? currentIndex - 1 : currentIndex + 1
        guard orderedInsertionIDs.indices.contains(targetIndex) else {
            return fallbackCursor(
                direction: direction,
                editorState: editorState
            )
        }

        return projectionSnapshot.cursor(for: orderedInsertionIDs[targetIndex])
            ?? fallbackCursor(direction: direction, editorState: editorState)
    }

    private static func resolveStructuralNavigation(
        direction: StructuralDirection,
        editorState: EditorState
    ) -> EditorCursor? {
        let navigator = EMathicaWorkspaceKit.EditorCursorNavigator(root: editorState.root)
        let candidate: EditorCursor
        switch direction {
        case .up:
            candidate = navigator.moveUp(from: editorState.cursor)
        case .down:
            candidate = navigator.moveDown(from: editorState.cursor)
        }

        if candidate != editorState.cursor {
            return candidate
        }

        return fallbackCursor(direction: direction, editorState: editorState)
    }

    private static func fallbackCursor(
        direction: LinearDirection,
        editorState: EditorState
    ) -> EditorCursor? {
        let navigator = EMathicaWorkspaceKit.EditorCursorNavigator(root: editorState.root)
        switch direction {
        case .left:
            return navigator.moveLeft(from: editorState.cursor)
        case .right:
            return navigator.moveRight(from: editorState.cursor)
        }
    }

    private static func fallbackCursor(
        direction: StructuralDirection,
        editorState: EditorState
    ) -> EditorCursor? {
        let navigator = EMathicaWorkspaceKit.EditorCursorNavigator(root: editorState.root)
        switch direction {
        case .up:
            return navigator.moveUp(from: editorState.cursor)
        case .down:
            return navigator.moveDown(from: editorState.cursor)
        }
    }

    private static func currentInsertionID(
        for direction: LinearDirection,
        currentIDs: [FormulaInsertionID],
        orderedIndices: [FormulaInsertionID: Int]
    ) -> FormulaInsertionID? {
        let sorted = currentIDs.sorted {
            (orderedIndices[$0] ?? Int.max) < (orderedIndices[$1] ?? Int.max)
        }
        switch direction {
        case .left:
            return sorted.last ?? sorted.first
        case .right:
            return sorted.first ?? sorted.last
        }
    }

    private static func orderedInsertionIDs(in node: FormulaDisplayNode) -> [FormulaInsertionID] {
        var orderedIDs: [FormulaInsertionID] = []
        appendInsertionIDs(from: node, into: &orderedIDs)
        return orderedIDs
    }

    private static func appendInsertionIDs(
        from node: FormulaDisplayNode,
        into orderedIDs: inout [FormulaInsertionID]
    ) {
        switch node {
        case .sequence(let children):
            children.forEach { appendInsertionIDs(from: $0, into: &orderedIDs) }
        case .function(_, let arguments):
            arguments.forEach { appendInsertionIDs(from: $0, into: &orderedIDs) }
        case .fraction(let numerator, let denominator):
            appendInsertionIDs(from: numerator, into: &orderedIDs)
            appendInsertionIDs(from: denominator, into: &orderedIDs)
        case .sqrt(let radicand):
            appendInsertionIDs(from: radicand, into: &orderedIDs)
        case .nthRoot(let index, let radicand):
            appendInsertionIDs(from: index, into: &orderedIDs)
            appendInsertionIDs(from: radicand, into: &orderedIDs)
        case .superscript(let base, let exponent):
            appendInsertionIDs(from: base, into: &orderedIDs)
            appendInsertionIDs(from: exponent, into: &orderedIDs)
        case .subscript(let base, let subscriptNode):
            appendInsertionIDs(from: base, into: &orderedIDs)
            appendInsertionIDs(from: subscriptNode, into: &orderedIDs)
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            appendInsertionIDs(from: base, into: &orderedIDs)
            if let subscriptNode {
                appendInsertionIDs(from: subscriptNode, into: &orderedIDs)
            }
            if let superscriptNode {
                appendInsertionIDs(from: superscriptNode, into: &orderedIDs)
            }
        case .parentheses(let content),
                .brackets(let content),
                .braces(let content),
                .absoluteValue(let content),
                .accent(_, let content):
            appendInsertionIDs(from: content, into: &orderedIDs)
        case .matrix(_, let rows):
            rows.forEach { row in
                row.cells.forEach { appendInsertionIDs(from: $0, into: &orderedIDs) }
            }
        case .cases(let rows):
            rows.forEach { row in
                row.cells.forEach { appendInsertionIDs(from: $0, into: &orderedIDs) }
            }
        case .limit(let variable, let target, let body):
            appendInsertionIDs(from: variable, into: &orderedIDs)
            appendInsertionIDs(from: target, into: &orderedIDs)
            appendInsertionIDs(from: body, into: &orderedIDs)
        case .largeOperator(_, let variable, let lowerBound, let upperBound, let body):
            appendInsertionIDs(from: variable, into: &orderedIDs)
            appendInsertionIDs(from: lowerBound, into: &orderedIDs)
            appendInsertionIDs(from: upperBound, into: &orderedIDs)
            appendInsertionIDs(from: body, into: &orderedIDs)
        case .integral(let lowerBound, let upperBound, let integrand, let variable):
            appendInsertionIDs(from: lowerBound, into: &orderedIDs)
            appendInsertionIDs(from: upperBound, into: &orderedIDs)
            appendInsertionIDs(from: integrand, into: &orderedIDs)
            appendInsertionIDs(from: variable, into: &orderedIDs)
        case .parametric2D(let x, let y, let range):
            appendInsertionIDs(from: x, into: &orderedIDs)
            appendInsertionIDs(from: y, into: &orderedIDs)
            if let range {
                appendInsertionIDs(from: range, into: &orderedIDs)
            }
        case .parametric3D(let x, let y, let z):
            appendInsertionIDs(from: x, into: &orderedIDs)
            appendInsertionIDs(from: y, into: &orderedIDs)
            appendInsertionIDs(from: z, into: &orderedIDs)
        case .piecewise(let rows):
            rows.forEach { row in
                appendInsertionIDs(from: row.expression, into: &orderedIDs)
                appendInsertionIDs(from: row.condition, into: &orderedIDs)
            }
        case .insertionMarker(let token):
            orderedIDs.append(token.id)
        case .cursor, .placeholder, .text, .operatorSymbol, .raw, .error:
            break
        }
    }
}
