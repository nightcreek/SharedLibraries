import Foundation

public final class InputController {
    public init() {}
    private let cursorController = CursorController()

    public func handle(_ action: KeyboardAction, state: inout EditorState) {
        let canonicalAction = Self.canonicalAction(for: action)

        switch canonicalAction {
        case .insertCharacter(let value):
            if value == "," {
                if routeParametricRangeTrigger(",", state: &state) {
                    return
                }
            } else if value == "(" {
                if routeParametricRangeTrigger("(", state: &state) {
                    return
                }
            }
            if value == "^" {
                insertTemplate(.superscript, into: &state)
                return
            }
            insert(.character(value), into: &state)
        case .insertSymbol(let value):
            insert(.symbol(value), into: &state)
        case .insertOperator(let value):
            if value == "," {
                if routeParametricRangeTrigger(",", state: &state) {
                    return
                }
            } else if value == "(" {
                if routeParametricRangeTrigger("(", state: &state) {
                    return
                }
            }
            if value == "^" {
                insertTemplate(.superscript, into: &state)
                return
            }
            insert(.operatorSymbol(value), into: &state)
        case .insertTemplate(let kind):
            insertTemplate(kind, into: &state)
        case .insertFunction(let name):
            insertTemplate(functionKind(for: name), into: &state)
        case .moveLeft:
            cursorController.moveCursorLeft(state: &state)
        case .moveRight:
            cursorController.moveCursorRight(state: &state)
        case .moveUp:
            cursorController.moveCursorUp(state: &state)
        case .moveDown:
            cursorController.moveCursorDown(state: &state)
        case .tab:
            cursorController.moveCursorNextMajorSlot(state: &state)
        case .shiftTab:
            cursorController.moveCursorPreviousMajorSlot(state: &state)
        case .deleteBackward:
            backspace(state: &state)
        case .deleteForward:
            deleteForward(state: &state)
        case .submit, .cancel:
            break
        case .backspace, .delete, .enter:
            break
        }
    }

    static func canonicalAction(for action: KeyboardAction) -> KeyboardAction {
        switch action {
        case .backspace:
            return .deleteBackward
        case .delete:
            return .deleteForward
        case .enter:
            return .submit
        default:
            return action
        }
    }

    private func insert(_ node: MathNode, into state: inout EditorState) {
        replaceSelectionIfNeeded(in: &state)
        guard var sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root) else { return }
        let offset = prepareSequenceForInsertion(sequence: &sequence, cursorOffset: &state.cursor.offset)
        sequence.insert(node, at: offset)
        MathEditorTree.setSequence(sequence, at: state.cursor.path, in: &state.root)
        state.cursor.offset = offset + 1
        state.selection = nil
    }

    private func insertTemplate(_ kind: TemplateKind, into state: inout EditorState) {
        let wrappedSelection = consumeSelectionForTemplateIfNeeded(in: &state)
        guard var sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root) else { return }
        let insertionOffset = prepareSequenceForInsertion(sequence: &sequence, cursorOffset: &state.cursor.offset)

        if kind == .superscript,
           let context = MathEditorTree.currentTemplateContext(for: state.cursor, in: state.root),
           context.template.kind == .superscript,
           context.field == .exponent,
           let exponentSequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root),
           (exponentSequence.isEmpty || exponentSequence.allSatisfy(\.isEmptyForEditing)) {
            return
        }

        let definition = TemplateDefinitionRegistry.definition(for: kind)
        var fields = definition.fields.map { fieldID in
            TemplateField(
                id: fieldID,
                node: defaultNode(for: fieldID, templateKind: kind)
            )
        }
        var initialField = definition.initialField
        if let wrappedSelection {
            applyWrappedSelection(
                wrappedSelection,
                to: &fields,
                kind: kind,
                initialField: &initialField
            )
        }

        if case .superscript = kind, insertionOffset > 0 {
            let baseIndex = insertionOffset - 1
            if baseIndex < sequence.count {
                let candidate = sequence[baseIndex]
                if isValidSuperscriptBase(candidate) {
                    let base = sequence.remove(at: baseIndex)
                    if let index = fields.firstIndex(where: { $0.id == .base }) {
                        fields[index].node = .sequence([base])
                    }
                    state.cursor.offset = baseIndex
                    initialField = .exponent
                } else {
                    initialField = .base
                }
            } else {
                initialField = .base
            }
        } else if case .superscript = kind {
            initialField = .base
        }

        if case .subscriptTemplate = kind, insertionOffset > 0 {
            let baseIndex = insertionOffset - 1
            if baseIndex < sequence.count {
                let candidate = sequence[baseIndex]
                if isValidSuperscriptBase(candidate) {
                    let base = sequence.remove(at: baseIndex)
                    if let index = fields.firstIndex(where: { $0.id == .base }) {
                        fields[index].node = .sequence([base])
                    }
                    state.cursor.offset = baseIndex
                } else {
                    initialField = .base
                }
            } else {
                initialField = .base
            }
        } else if case .subscriptTemplate = kind {
            initialField = .base
        }

        let templateNode = MathNode.template(TemplateNode(kind: kind, fields: fields))
        let insertIndex = max(0, min(sequence.count, state.cursor.offset))
        sequence.insert(templateNode, at: insertIndex)
        MathEditorTree.setSequence(sequence, at: state.cursor.path, in: &state.root)

        state.cursor.path.append(.sequenceIndex(insertIndex))
        state.cursor.path.append(.templateField(initialField))
        state.cursor.offset = 0
        state.selection = nil
    }

    private func consumeSelectionForTemplateIfNeeded(in state: inout EditorState) -> MathNode? {
        guard let selection = state.selection,
              selection.anchor.path == selection.focus.path else {
            return nil
        }
        let path = selection.anchor.path
        guard var sequence = MathEditorTree.sequence(at: path, in: state.root) else {
            state.selection = nil
            return nil
        }
        let start = max(0, min(sequence.count, min(selection.anchor.offset, selection.focus.offset)))
        let end = max(start, min(sequence.count, max(selection.anchor.offset, selection.focus.offset)))
        guard end > start else {
            state.selection = nil
            return nil
        }
        let selectedNodes = Array(sequence[start..<end])
        sequence.removeSubrange(start..<end)
        MathEditorTree.setSequence(sequence, at: path, in: &state.root)
        state.cursor = EditorCursor(path: path, offset: start)
        state.selection = nil
        return .sequence(selectedNodes)
    }

    private func applyWrappedSelection(
        _ selectionNode: MathNode,
        to fields: inout [TemplateField],
        kind: TemplateKind,
        initialField: inout FieldID
    ) {
        func setField(_ id: FieldID, to node: MathNode) {
            if let idx = fields.firstIndex(where: { $0.id == id }) {
                fields[idx].node = node
            }
        }

        switch kind {
        case .fraction:
            setField(.numerator, to: selectionNode)
            initialField = .denominator
        case .superscript:
            setField(.base, to: selectionNode)
            initialField = .exponent
        case .subscriptTemplate:
            setField(.base, to: selectionNode)
            initialField = .subscriptField
        case .subscriptSuperscript:
            setField(.base, to: selectionNode)
            initialField = .subscriptField
        case .log:
            setField(.argument, to: selectionNode)
            initialField = .base
        case .nthRoot:
            setField(.radicand, to: selectionNode)
            initialField = .rootIndex
        case .sqrt:
            setField(.radicand, to: selectionNode)
            initialField = .radicand
        case .sin, .cos, .tan, .ln, .exp:
            setField(.argument, to: selectionNode)
            initialField = .argument
        case .parentheses, .brackets, .braces, .absoluteValue, .vector, .overline, .hat:
            setField(.content, to: selectionNode)
            initialField = .content
        default:
            setField(initialField, to: selectionNode)
        }
    }

    private func prepareSequenceForInsertion(sequence: inout [MathNode], cursorOffset: inout Int) -> Int {
        if sequence.count == 1, sequence[0].isEmptyForEditing {
            sequence.removeAll()
            cursorOffset = 0
            return 0
        }

        var offset = max(0, min(sequence.count, cursorOffset))
        if sequence.indices.contains(offset), sequence[offset].isEmptyForEditing {
            sequence.remove(at: offset)
        } else if offset > 0, sequence.indices.contains(offset - 1), sequence[offset - 1].isEmptyForEditing {
            sequence.remove(at: offset - 1)
            offset -= 1
        }
        cursorOffset = offset
        return offset
    }

    private func backspace(state: inout EditorState) {
        if replaceSelectionIfNeeded(in: &state) {
            normalizeCurrentSequenceAfterMutation(state: &state)
            return
        }
        guard var sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root) else { return }

        if state.cursor.offset > 0 {
            let idx = state.cursor.offset - 1
            guard idx < sequence.count else { return }
            let target = sequence[idx]
            if case .template(let template) = target, template.fields.allSatisfy({ $0.node.isEmptyForEditing }) {
                sequence.remove(at: idx)
            } else {
                sequence.remove(at: idx)
            }
            MathEditorTree.setSequence(sequence, at: state.cursor.path, in: &state.root)
            state.cursor.offset = idx
            normalizeCurrentSequenceAfterMutation(state: &state)
            return
        }

        if handleTemplateBoundaryBackspace(state: &state) {
            normalizeCurrentSequenceAfterMutation(state: &state)
            return
        }

        if let exitCursor = MathEditorTree.cursorExitingCurrentField(state.cursor) {
            state.cursor = exitCursor
        }
    }

    private func deleteForward(state: inout EditorState) {
        guard var sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root) else { return }
        guard state.cursor.offset < sequence.count else { return }
        sequence.remove(at: state.cursor.offset)
        MathEditorTree.setSequence(sequence, at: state.cursor.path, in: &state.root)
        normalizeCurrentSequenceAfterMutation(state: &state)
    }

    @discardableResult
    private func replaceSelectionIfNeeded(in state: inout EditorState) -> Bool {
        guard let selection = state.selection,
              selection.anchor.path == selection.focus.path else {
            return false
        }
        let start = min(selection.anchor.offset, selection.focus.offset)
        let end = max(selection.anchor.offset, selection.focus.offset)
        guard var sequence = MathEditorTree.sequence(at: selection.anchor.path, in: state.root) else {
            state.selection = nil
            return false
        }
        let clampedStart = max(0, min(sequence.count, start))
        let clampedEnd = max(clampedStart, min(sequence.count, end))
        sequence.removeSubrange(clampedStart..<clampedEnd)
        MathEditorTree.setSequence(sequence, at: selection.anchor.path, in: &state.root)
        state.cursor = EditorCursor(path: selection.anchor.path, offset: clampedStart)
        state.selection = nil
        return true
    }

    private func functionKind(for name: String) -> TemplateKind {
        switch name.lowercased() {
        case "sin": return .sin
        case "cos": return .cos
        case "tan": return .tan
        case "ln": return .ln
        case "exp": return .exp
        case "log": return .log
        case "abs": return .absoluteValue
        default: return .sin
        }
    }

    private func defaultNode(for fieldID: FieldID, templateKind: TemplateKind) -> MathNode {
        return .sequence([.placeholder])
    }

    private func normalizeCurrentSequenceAfterMutation(state: inout EditorState) {
        guard var sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root) else { return }
        if sequence.isEmpty {
            sequence = [.placeholder]
            MathEditorTree.setSequence(sequence, at: state.cursor.path, in: &state.root)
            state.cursor.offset = 0
            return
        }
        if sequence.count > 1 {
            sequence.removeAll(where: \.isEmptyForEditing)
            if sequence.isEmpty {
                sequence = [.placeholder]
                state.cursor.offset = 0
            } else {
                state.cursor.offset = max(0, min(sequence.count, state.cursor.offset))
            }
            MathEditorTree.setSequence(sequence, at: state.cursor.path, in: &state.root)
        } else {
            state.cursor.offset = max(0, min(sequence.count, state.cursor.offset))
        }
    }

    @discardableResult
    private func routeParametricRangeTrigger(_ trigger: String, state: inout EditorState) -> Bool {
        if routeParametricRangeFromTemplateField(state: &state) {
            if trigger == "(" {
                insert(.character("("), into: &state)
            }
            return true
        }

        if routeParametricRangeFromParentSequence(state: &state) {
            if trigger == "(" {
                insert(.character("("), into: &state)
            }
            return true
        }

        return false
    }

    private func routeParametricRangeFromTemplateField(state: inout EditorState) -> Bool {
        guard let context = MathEditorTree.currentTemplateContext(for: state.cursor, in: state.root),
              context.template.kind == .parametricEquation2D,
              context.field == .parametricExpression(1),
              let currentField = MathEditorTree.sequence(at: state.cursor.path, in: state.root),
              state.cursor.offset == currentField.count,
              let rangeNode = context.template.field(.parametricRange),
              rangeNode.isEmptyForEditing else {
            return false
        }

        state.cursor.path = context.templatePath + [.templateField(.parametricRange)]
        state.cursor.offset = 0
        return true
    }

    private func routeParametricRangeFromParentSequence(state: inout EditorState) -> Bool {
        guard let sequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root),
              state.cursor.offset > 0,
              let targetIndex = sequence.indices.contains(state.cursor.offset - 1) ? state.cursor.offset - 1 : nil,
              case .template(let template) = sequence[targetIndex],
              template.kind == .parametricEquation2D,
              let rangeNode = template.field(.parametricRange),
              rangeNode.isEmptyForEditing else {
            return false
        }

        // Cursor is after the template node; route trigger into dedicated range slot.
        state.cursor.path.append(.sequenceIndex(targetIndex))
        state.cursor.path.append(.templateField(.parametricRange))
        state.cursor.offset = 0
        return true
    }

    private func handleTemplateBoundaryBackspace(state: inout EditorState) -> Bool {
        guard let context = MathEditorTree.currentTemplateContext(for: state.cursor, in: state.root),
              let fieldSequence = MathEditorTree.sequence(at: state.cursor.path, in: state.root),
              fieldSequence.isEmpty || fieldSequence.allSatisfy(\.isEmptyForEditing),
              let templateIndex = MathEditorTree.templateIndexAndParentPath(from: context.templatePath),
              var parentSequence = MathEditorTree.sequence(at: templateIndex.parentPath, in: state.root),
              templateIndex.index < parentSequence.count else {
            return false
        }

        switch context.template.kind {
        case .superscript:
            let baseNode = context.template.field(.base) ?? .sequence([])
            parentSequence.remove(at: templateIndex.index)
            MathEditorTree.splice(node: baseNode, into: &parentSequence, at: templateIndex.index)
            MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
            let newOffset = templateIndex.index + MathEditorTree.sequenceContentCount(of: baseNode)
            state.cursor = EditorCursor(path: templateIndex.parentPath, offset: newOffset)
            return true

        case .subscriptTemplate, .subscriptSuperscript:
            let baseNode = context.template.field(.base) ?? .sequence([])
            parentSequence.remove(at: templateIndex.index)
            MathEditorTree.splice(node: baseNode, into: &parentSequence, at: templateIndex.index)
            MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
            let newOffset = templateIndex.index + MathEditorTree.sequenceContentCount(of: baseNode)
            state.cursor = EditorCursor(path: templateIndex.parentPath, offset: newOffset)
            return true

        case .sqrt, .nthRoot, .absoluteValue, .parentheses, .brackets, .braces:
            parentSequence.remove(at: templateIndex.index)
            MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
            state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
            return true

        case .fraction:
            let numeratorEmpty = (context.template.field(.numerator) ?? .placeholder).isEmptyForEditing
            let denominatorEmpty = (context.template.field(.denominator) ?? .placeholder).isEmptyForEditing
            if numeratorEmpty && denominatorEmpty {
                parentSequence.remove(at: templateIndex.index)
                MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                return true
            }
            if context.field == .denominator {
                if numeratorEmpty {
                    parentSequence.remove(at: templateIndex.index)
                    MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                    state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                } else {
                    moveCursorToTemplateFieldEnd(.numerator, in: context.templatePath, state: &state)
                }
                return true
            }
            if numeratorEmpty {
                parentSequence.remove(at: templateIndex.index)
                MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                return true
            }
            return false

        case .sin, .cos, .tan, .ln, .exp:
            parentSequence.remove(at: templateIndex.index)
            MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
            state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
            return true

        case .log:
            let baseEmpty = (context.template.field(.base) ?? .placeholder).isEmptyForEditing
            let argumentEmpty = (context.template.field(.argument) ?? .placeholder).isEmptyForEditing
            if baseEmpty && argumentEmpty {
                parentSequence.remove(at: templateIndex.index)
                MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                return true
            }
            if context.field == .argument, !baseEmpty {
                moveCursorToTemplateFieldEnd(.base, in: context.templatePath, state: &state)
                return true
            }
            if context.field == .base, argumentEmpty {
                parentSequence.remove(at: templateIndex.index)
                MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                return true
            }
            return false

        case .piecewise(let rows):
            if allTemplateFieldsEmpty(context.template) {
                parentSequence.remove(at: templateIndex.index)
                MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                return true
            }
            if let previousField = previousPiecewiseField(current: context.field, rows: rows) {
                moveCursorToTemplateFieldEnd(previousField, in: context.templatePath, state: &state)
                return true
            }
            return false

        case .parametricEquation2D:
            if allTemplateFieldsEmpty(context.template) {
                parentSequence.remove(at: templateIndex.index)
                MathEditorTree.setSequence(parentSequence, at: templateIndex.parentPath, in: &state.root)
                state.cursor = EditorCursor(path: templateIndex.parentPath, offset: templateIndex.index)
                return true
            }
            if let previousField = previousParametricField(current: context.field) {
                moveCursorToTemplateFieldEnd(previousField, in: context.templatePath, state: &state)
                return true
            }
            return false

        default:
            return false
        }
    }

    private func allTemplateFieldsEmpty(_ template: TemplateNode) -> Bool {
        template.fields.allSatisfy { $0.node.isEmptyForEditing }
    }

    private func moveCursorToTemplateFieldEnd(
        _ field: FieldID,
        in templatePath: [EditorPathComponent],
        state: inout EditorState
    ) {
        state.cursor.path = templatePath + [.templateField(field)]
        state.cursor.offset = MathEditorTree.sequence(at: state.cursor.path, in: state.root)?.count ?? 0
    }

    private func previousPiecewiseField(current: FieldID, rows: Int) -> FieldID? {
        let order = (0..<rows).flatMap { row in
            [FieldID.rowExpression(row), .rowCondition(row)]
        }
        guard let index = order.firstIndex(of: current), index > 0 else {
            return nil
        }
        return order[index - 1]
    }

    private func previousParametricField(current: FieldID) -> FieldID? {
        switch current {
        case .parametricExpression(1):
            return .parametricExpression(0)
        case .parametricRange:
            return .parametricExpression(1)
        default:
            return nil
        }
    }

    private func isValidSuperscriptBase(_ node: MathNode) -> Bool {
        switch node {
        case .placeholder:
            return false
        case .template:
            return true
        case .symbol:
            return true
        case .character(let value):
            guard value.count == 1 else { return false }
            let forbidden: Set<Character> = ["=", "+", "-", "*", "/", ",", ";", ":", "(", "[", "{", "}", " "]
            guard let ch = value.first else { return false }
            return !forbidden.contains(ch)
        case .operatorSymbol(let value):
            let forbidden = ["=", "+", "-", "*", "/", ",", ";", ":"]
            return !forbidden.contains(value)
        case .sequence(let nodes):
            guard !nodes.isEmpty else { return false }
            if nodes.count == 1 {
                return isValidSuperscriptBase(nodes[0])
            }
            return false
        }
    }
}

final class CursorController {
    public func moveCursorLeft(state: inout EditorState) {
        let navigator = EditorCursorNavigator(root: state.root)
        state.cursor = navigator.moveLeft(from: state.cursor)
    }

    public func moveCursorRight(state: inout EditorState) {
        let navigator = EditorCursorNavigator(root: state.root)
        state.cursor = navigator.moveRight(from: state.cursor)
    }

    public func moveCursorUp(state: inout EditorState) {
        let navigator = EditorCursorNavigator(root: state.root)
        state.cursor = navigator.moveUp(from: state.cursor)
    }

    public func moveCursorDown(state: inout EditorState) {
        let navigator = EditorCursorNavigator(root: state.root)
        state.cursor = navigator.moveDown(from: state.cursor)
    }

    public func moveCursorNextMajorSlot(state: inout EditorState) {
        let navigator = EditorCursorNavigator(root: state.root)
        state.cursor = navigator.moveNextMajorSlot(from: state.cursor)
    }

    public func moveCursorPreviousMajorSlot(state: inout EditorState) {
        let navigator = EditorCursorNavigator(root: state.root)
        state.cursor = navigator.movePreviousMajorSlot(from: state.cursor)
    }

    @discardableResult
    public func exitCurrentTemplate(state: inout EditorState, reverse: Bool = false) -> Bool {
        let navigator = EditorCursorNavigator(root: state.root)
        let old = state.cursor
        state.cursor = navigator.exitCurrentTemplate(from: state.cursor, reverse: reverse)
        return state.cursor != old
    }
}

public enum MathEditorTree {
    public static func sequence(at path: [EditorPathComponent], in root: MathNode) -> [MathNode]? {
        switch node(at: path, in: root) {
        case .sequence(let nodes)?:
            return nodes
        default:
            return nil
        }
    }

    public static func setSequence(_ sequence: [MathNode], at path: [EditorPathComponent], in root: inout MathNode) {
        setNode(.sequence(sequence), at: path, in: &root)
    }

    public static func node(at path: [EditorPathComponent], in root: MathNode) -> MathNode? {
        var current = root
        for step in path {
            switch (step, current) {
            case (.sequenceIndex(let index), .sequence(let nodes)):
                guard nodes.indices.contains(index) else { return nil }
                current = nodes[index]
            case (.templateField(let fieldID), .template(let template)):
                guard let field = template.fields.first(where: { $0.id == fieldID }) else { return nil }
                current = field.node
            default:
                return nil
            }
        }
        return current
    }

    public static func setNode(_ newNode: MathNode, at path: [EditorPathComponent], in root: inout MathNode) {
        guard let first = path.first else {
            root = newNode
            return
        }
        switch (first, root) {
        case (.sequenceIndex(let index), .sequence(var nodes)):
            guard nodes.indices.contains(index) else { return }
            setNode(newNode, at: Array(path.dropFirst()), in: &nodes[index])
            root = .sequence(nodes)
        case (.templateField(let fieldID), .template(var template)):
            guard let fieldIndex = template.fields.firstIndex(where: { $0.id == fieldID }) else { return }
            setNode(newNode, at: Array(path.dropFirst()), in: &template.fields[fieldIndex].node)
            root = .template(template)
        default:
            return
        }
    }

    public static func cursorExitingCurrentField(_ cursor: EditorCursor) -> EditorCursor? {
        guard cursor.path.count >= 2 else { return nil }
        guard case .templateField = cursor.path.last else { return nil }
        return EditorCursor(path: Array(cursor.path.dropLast(2)), offset: parentSequenceIndex(in: cursor.path))
    }

    public static func currentTemplateContext(for cursor: EditorCursor, in root: MathNode) -> (template: TemplateNode, templatePath: [EditorPathComponent], field: FieldID)? {
        guard cursor.path.count >= 2 else { return nil }
        guard case .templateField(let fieldID) = cursor.path.last else { return nil }
        let templatePath = Array(cursor.path.dropLast())
        guard case .template(let template)? = node(at: templatePath, in: root) else { return nil }
        return (template: template, templatePath: templatePath, field: fieldID)
    }

    public static func templateIndexAndParentPath(from templatePath: [EditorPathComponent]) -> (parentPath: [EditorPathComponent], index: Int)? {
        guard let last = templatePath.last, case .sequenceIndex(let index) = last else { return nil }
        return (parentPath: Array(templatePath.dropLast()), index: index)
    }

    public static func splice(node: MathNode, into sequence: inout [MathNode], at index: Int) {
        switch node {
        case .sequence(let nodes):
            sequence.insert(contentsOf: nodes, at: index)
        default:
            sequence.insert(node, at: index)
        }
    }

    public static func sequenceContentCount(of node: MathNode) -> Int {
        switch node {
        case .sequence(let nodes):
            return nodes.count
        default:
            return 1
        }
    }

    private static func parentSequenceIndex(in path: [EditorPathComponent]) -> Int {
        for component in path.reversed() {
            if case .sequenceIndex(let idx) = component {
                return idx
            }
        }
        return 0
    }
}
