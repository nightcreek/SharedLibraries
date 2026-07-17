import Foundation

public struct FormulaKeyDefinition: FormulaKeyboardPrimitive {
    public let id: FormulaKeyIdentifier
    public let presentation: FormulaKeyPresentation
    public let intent: FormulaKeyIntent
    public let layoutHint: FormulaKeyLayoutHint

    public init(
        id: FormulaKeyIdentifier,
        presentation: FormulaKeyPresentation,
        intent: FormulaKeyIntent,
        layoutHint: FormulaKeyLayoutHint
    ) {
        self.id = id
        self.presentation = presentation
        self.intent = intent
        self.layoutHint = layoutHint
    }
}
