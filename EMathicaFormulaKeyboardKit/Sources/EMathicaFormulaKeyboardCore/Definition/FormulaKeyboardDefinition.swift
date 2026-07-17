import Foundation

public struct FormulaKeyboardDefinition: FormulaKeyboardPrimitive {
    public let metadata: FormulaKeyboardMetadata
    public let defaultPageID: FormulaKeyboardPageIdentifier
    public let pages: [FormulaKeyboardPageDefinition]

    public init(
        metadata: FormulaKeyboardMetadata,
        defaultPageID: FormulaKeyboardPageIdentifier,
        pages: [FormulaKeyboardPageDefinition]
    ) throws {
        let candidate = FormulaKeyboardDefinition(
            metadata: metadata,
            defaultPageID: defaultPageID,
            pages: pages,
            skipValidation: true
        )
        try FormulaKeyboardDefinitionValidator().validate(candidate)
        self = candidate
    }

    public init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case metadata
            case defaultPageID
            case pages
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadata = try container.decode(FormulaKeyboardMetadata.self, forKey: .metadata)
        let defaultPageID = try container.decode(FormulaKeyboardPageIdentifier.self, forKey: .defaultPageID)
        let pages = try container.decode([FormulaKeyboardPageDefinition].self, forKey: .pages)
        try self.init(metadata: metadata, defaultPageID: defaultPageID, pages: pages)
    }

    private init(
        metadata: FormulaKeyboardMetadata,
        defaultPageID: FormulaKeyboardPageIdentifier,
        pages: [FormulaKeyboardPageDefinition],
        skipValidation: Bool
    ) {
        self.metadata = metadata
        self.defaultPageID = defaultPageID
        self.pages = pages
    }
}
