import Foundation

public struct ProjectMetadata: Identifiable, Hashable, Codable {
    public let id: UUID
    public var title: String
    public var moduleID: String
    public var createdAt: Date
    public var updatedAt: Date
    public var version: String
    public var previewImageName: String
    public var calculatorType: String

    public init(
        id: UUID = UUID(),
        title: String,
        moduleID: String,
        createdAt: Date,
        updatedAt: Date,
        version: String = "0.1",
        previewImageName: String = "preview.png",
        calculatorType: String
    ) {
        self.id = id
        self.title = title
        self.moduleID = moduleID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.previewImageName = previewImageName
        self.calculatorType = calculatorType
    }
}
