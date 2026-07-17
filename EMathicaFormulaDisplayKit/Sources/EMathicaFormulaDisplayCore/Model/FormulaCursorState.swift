import Foundation

public struct FormulaSelectionState: Equatable, Sendable {
    public var startAnchor: FormulaCursorAnchor
    public var endAnchor: FormulaCursorAnchor

    public init(startAnchor: FormulaCursorAnchor, endAnchor: FormulaCursorAnchor) {
        self.startAnchor = startAnchor
        self.endAnchor = endAnchor
    }
}

public struct FormulaCursorState: Equatable, Sendable {
    public var insertionPoint: FormulaCursorAnchor
    public var selectionEnd: FormulaCursorAnchor?

    public init(
        insertionPoint: FormulaCursorAnchor,
        selectionEnd: FormulaCursorAnchor? = nil
    ) {
        self.insertionPoint = insertionPoint
        self.selectionEnd = selectionEnd
    }

    public var selectionState: FormulaSelectionState? {
        guard let selectionEnd else { return nil }
        return FormulaSelectionState(
            startAnchor: insertionPoint,
            endAnchor: selectionEnd
        )
    }
}
