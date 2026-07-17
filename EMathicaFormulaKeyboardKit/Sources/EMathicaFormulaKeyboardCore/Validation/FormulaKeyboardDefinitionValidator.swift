import Foundation

public struct FormulaKeyboardDefinitionValidator: Sendable {
    public init() {}

    public func validate(_ definition: FormulaKeyboardDefinition) throws {
        guard !definition.pages.isEmpty else {
            throw FormulaKeyboardDefinitionError.emptyPages
        }

        let pageIDs = definition.pages.map(\.id)
        try ensureUnique(pageIDs, duplicate: FormulaKeyboardDefinitionError.duplicatePageIdentifier)

        guard pageIDs.contains(definition.defaultPageID) else {
            throw FormulaKeyboardDefinitionError.missingDefaultPage(definition.defaultPageID)
        }

        let sectionIDs = definition.pages.flatMap { $0.sections.map(\.id) }
        try ensureUnique(sectionIDs, duplicate: FormulaKeyboardDefinitionError.duplicateSectionIdentifier)

        let rowIDs = definition.pages
            .flatMap { $0.sections }
            .flatMap { $0.rows.map(\.id) }
        try ensureUnique(rowIDs, duplicate: FormulaKeyboardDefinitionError.duplicateRowIdentifier)

        let keyIDs = definition.pages
            .flatMap { $0.sections }
            .flatMap { $0.rows }
            .flatMap { $0.keys.map(\.id) }
        try ensureUnique(keyIDs, duplicate: FormulaKeyboardDefinitionError.duplicateKeyIdentifier)
    }

    private func ensureUnique<ID: Hashable>(
        _ identifiers: [ID],
        duplicate: (ID) -> FormulaKeyboardDefinitionError
    ) throws {
        var seen: Set<ID> = []
        for identifier in identifiers {
            let inserted = seen.insert(identifier).inserted
            if !inserted {
                throw duplicate(identifier)
            }
        }
    }
}
