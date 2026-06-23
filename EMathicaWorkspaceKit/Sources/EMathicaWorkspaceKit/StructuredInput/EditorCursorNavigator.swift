import EMathicaMathInputCore
import EMathicaMathCore
import Foundation

public struct EditorCursorNavigator {
    public enum VerticalDirection {
        case up
        case down
    }

    public enum CursorPlacement {
        case start
        case end
        case preserveOffset
    }

    public let root: MathNode

    public init(root: MathNode) {
        self.root = root
    }

    public func moveLeft(from cursor: EditorCursor) -> EditorCursor {
        if let moved = moveAlongTemplateFieldBoundary(from: cursor, reverse: true) {
            return moved
        }

        if let context = MathEditorTree.currentTemplateContext(for: cursor, in: root),
           context.template.kind == .superscript,
           context.field == .exponent,
           cursor.offset == 0 {
            let basePath = context.templatePath + [.templateField(.base)]
            return EditorCursor(path: basePath, offset: MathEditorTree.sequence(at: basePath, in: root)?.count ?? 0)
        }

        if cursor.offset > 0,
           let sequence = MathEditorTree.sequence(at: cursor.path, in: root) {
            let targetIndex = cursor.offset - 1
            if sequence.indices.contains(targetIndex),
               case .template(let template) = sequence[targetIndex] {
                let definition = TemplateDefinitionRegistry.definition(for: template.kind)
                if let lastField = definition.tabOrder.last {
                    let targetPath = cursor.path + [.sequenceIndex(targetIndex), .templateField(lastField)]
                    return EditorCursor(path: targetPath, offset: MathEditorTree.sequence(at: targetPath, in: root)?.count ?? 0)
                }
            }
            return EditorCursor(path: cursor.path, offset: cursor.offset - 1)
        }
        return MathEditorTree.cursorExitingCurrentField(cursor) ?? cursor
    }

    public func moveRight(from cursor: EditorCursor) -> EditorCursor {
        if let moved = moveAlongTemplateFieldBoundary(from: cursor, reverse: false) {
            return moved
        }

        guard let sequence = MathEditorTree.sequence(at: cursor.path, in: root) else { return cursor }
        if cursor.offset < sequence.count {
            let targetIndex = cursor.offset
            if sequence.indices.contains(targetIndex),
               case .template(let template) = sequence[targetIndex] {
                let definition = TemplateDefinitionRegistry.definition(for: template.kind)
                return EditorCursor(
                    path: cursor.path + [.sequenceIndex(targetIndex), .templateField(definition.initialField)],
                    offset: 0
                )
            }
            return EditorCursor(path: cursor.path, offset: cursor.offset + 1)
        }
        if var parent = MathEditorTree.cursorExitingCurrentField(cursor) {
            parent.offset += 1
            return parent
        }
        return cursor
    }

    public func moveUp(from cursor: EditorCursor) -> EditorCursor {
        moveWithinTemplate(from: cursor, direction: .up)
    }

    public func moveDown(from cursor: EditorCursor) -> EditorCursor {
        moveWithinTemplate(from: cursor, direction: .down)
    }

    public func moveNextMajorSlot(from cursor: EditorCursor) -> EditorCursor {
        moveTab(from: cursor, reverse: false)
    }

    public func movePreviousMajorSlot(from cursor: EditorCursor) -> EditorCursor {
        moveTab(from: cursor, reverse: true)
    }

    public func exitCurrentTemplate(from cursor: EditorCursor, reverse: Bool) -> EditorCursor {
        guard let context = MathEditorTree.currentTemplateContext(for: cursor, in: root),
              let target = Self.exitTemplateCursor(templatePath: context.templatePath, reverse: reverse) else {
            return cursor
        }
        return target
    }

    private func moveWithinTemplate(from cursor: EditorCursor, direction: VerticalDirection) -> EditorCursor {
        guard let context = MathEditorTree.currentTemplateContext(for: cursor, in: root),
              let targetField = Self.verticalNeighborField(
                currentField: context.field,
                direction: direction,
                templateKind: context.template.kind
              ) else {
            return cursor
        }
        return fieldCursor(
            templatePath: context.templatePath,
            field: targetField,
            placement: .preserveOffset,
            currentOffset: cursor.offset
        )
    }

    private func moveTab(from cursor: EditorCursor, reverse: Bool) -> EditorCursor {
        guard let context = MathEditorTree.currentTemplateContext(for: cursor, in: root) else {
            return reverse ? moveLeft(from: cursor) : moveRight(from: cursor)
        }
        let definition = TemplateDefinitionRegistry.definition(for: context.template.kind)
        let targetField = reverse
            ? Self.previousFieldInTabOrder(currentField: context.field, templateDefinition: definition)
            : Self.nextFieldInTabOrder(currentField: context.field, templateDefinition: definition)
        if let targetField {
            return fieldCursor(
                templatePath: context.templatePath,
                field: targetField,
                placement: reverse ? .end : .start,
                currentOffset: cursor.offset
            )
        }
        return exitCurrentTemplate(from: cursor, reverse: reverse)
    }

    private func moveAlongTemplateFieldBoundary(from cursor: EditorCursor, reverse: Bool) -> EditorCursor? {
        guard let context = MathEditorTree.currentTemplateContext(for: cursor, in: root),
              let currentSequence = MathEditorTree.sequence(at: cursor.path, in: root) else {
            return nil
        }
        let atBoundary = reverse ? cursor.offset == 0 : cursor.offset == currentSequence.count
        guard atBoundary else { return nil }

        let definition = TemplateDefinitionRegistry.definition(for: context.template.kind)
        guard let targets = definition.arrowNavigation[context.field] else { return nil }
        let targetField = reverse ? targets.left : targets.right
        guard let targetField else { return nil }
        return fieldCursor(
            templatePath: context.templatePath,
            field: targetField,
            placement: reverse ? .end : .start,
            currentOffset: cursor.offset
        )
    }

    private func fieldCursor(
        templatePath: [EditorPathComponent],
        field: FieldID,
        placement: CursorPlacement,
        currentOffset: Int
    ) -> EditorCursor {
        let path = templatePath + [.templateField(field)]
        let count = MathEditorTree.sequence(at: path, in: root)?.count ?? 0
        let offset: Int
        switch placement {
        case .start:
            offset = 0
        case .end:
            offset = count
        case .preserveOffset:
            offset = max(0, min(count, currentOffset))
        }
        return EditorCursor(path: path, offset: offset)
    }

    public static func nextFieldInTabOrder(currentField: FieldID, templateDefinition: TemplateDefinition) -> FieldID? {
        guard let currentIndex = templateDefinition.tabOrder.firstIndex(of: currentField) else { return nil }
        let nextIndex = currentIndex + 1
        guard nextIndex < templateDefinition.tabOrder.count else { return nil }
        return templateDefinition.tabOrder[nextIndex]
    }

    public static func previousFieldInTabOrder(currentField: FieldID, templateDefinition: TemplateDefinition) -> FieldID? {
        guard let currentIndex = templateDefinition.tabOrder.firstIndex(of: currentField) else { return nil }
        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else { return nil }
        return templateDefinition.tabOrder[previousIndex]
    }

    public static func verticalNeighborField(currentField: FieldID, direction: VerticalDirection, templateKind: TemplateKind) -> FieldID? {
        let definition = TemplateDefinitionRegistry.definition(for: templateKind)
        guard let targets = definition.arrowNavigation[currentField] else { return nil }
        switch direction {
        case .up:
            return targets.up
        case .down:
            return targets.down
        }
    }

    public static func exitTemplateCursor(templatePath: [EditorPathComponent], reverse: Bool) -> EditorCursor? {
        guard let indexAndParent = MathEditorTree.templateIndexAndParentPath(from: templatePath) else { return nil }
        let offset = reverse ? indexAndParent.index : indexAndParent.index + 1
        return EditorCursor(path: indexAndParent.parentPath, offset: offset)
    }
}
