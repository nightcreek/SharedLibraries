import Foundation

public struct RecentProject: Identifiable, Hashable, Codable {
    public let id: UUID
    public var title: String
    public var moduleID: String
    public var modifiedDateText: String
    public var thumbnailKindRawValue: String
    public var fileExtension: String
    public var isSelected: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        moduleID: String,
        modifiedDateText: String,
        thumbnailKindRawValue: String,
        fileExtension: String = ".emathica",
        isSelected: Bool = false
    ) {
        self.id = id
        self.title = title
        self.moduleID = moduleID
        self.modifiedDateText = modifiedDateText
        self.thumbnailKindRawValue = thumbnailKindRawValue
        self.fileExtension = fileExtension
        self.isSelected = isSelected
    }
}
