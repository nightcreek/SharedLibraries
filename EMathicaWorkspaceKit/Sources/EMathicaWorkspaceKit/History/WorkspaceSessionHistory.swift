import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

public struct WorkspaceUndoStep: Hashable {
    public var before: EMathicaDocument
    public var after: EMathicaDocument
    public var title: String
    public var timestamp: Date
}

public struct WorkspaceSessionHistory: Hashable {
    public var openBaseline: EMathicaDocument
    public var undoStack: [WorkspaceUndoStep] = []
    public var redoStack: [WorkspaceUndoStep] = []
    public var maxDepth: Int = 100

    public mutating func push(_ step: WorkspaceUndoStep) {
        undoStack.append(step)
        if undoStack.count > maxDepth {
            undoStack.removeFirst(undoStack.count - maxDepth)
        }
        redoStack.removeAll()
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }
}
