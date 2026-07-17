import EMathicaFormulaDisplayCore
import Foundation

public struct FormulaDisplayProjectionSnapshot: Equatable {
    public var document: FormulaDisplayDocument
    public var insertionCursors: [FormulaInsertionID: EditorCursor]

    public init(
        document: FormulaDisplayDocument,
        insertionCursors: [FormulaInsertionID: EditorCursor] = [:]
    ) {
        self.document = document
        self.insertionCursors = insertionCursors
    }

    public func cursor(for insertionID: FormulaInsertionID) -> EditorCursor? {
        insertionCursors[insertionID]
    }
}
