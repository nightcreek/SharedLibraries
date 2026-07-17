import Foundation

public enum FormulaKeyboardDefinitionError: Error, Hashable, Equatable, Codable, Sendable {
    case emptyPages
    case emptySections(pageID: FormulaKeyboardPageIdentifier)
    case emptyRows(sectionID: FormulaKeyboardSectionIdentifier)
    case emptyKeys(rowID: FormulaKeyboardRowIdentifier)
    case duplicatePageIdentifier(FormulaKeyboardPageIdentifier)
    case duplicateSectionIdentifier(FormulaKeyboardSectionIdentifier)
    case duplicateRowIdentifier(FormulaKeyboardRowIdentifier)
    case duplicateKeyIdentifier(FormulaKeyIdentifier)
    case invalidIdentifier(String)
    case invalidWidthWeight(Int)
    case missingDefaultPage(FormulaKeyboardPageIdentifier)
}
