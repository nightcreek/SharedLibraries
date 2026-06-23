import Foundation

public struct EMathicaPackageLayout {
    public init(rootURL: URL) { self.rootURL = rootURL }
    public static let packageExtension = "emathica"
    public static let metadataFileName = "metadata.json"
    public static let documentFileName = "document.json"
    public static let previewFileName = "preview.png"

    public let rootURL: URL

    public var metadataURL: URL {
        rootURL.appendingPathComponent(Self.metadataFileName, isDirectory: false)
    }

    public var documentURL: URL {
        rootURL.appendingPathComponent(Self.documentFileName, isDirectory: false)
    }

    public var previewURL: URL {
        rootURL.appendingPathComponent(Self.previewFileName, isDirectory: false)
    }

    public static func packageURL(for id: UUID, under projectsRootURL: URL) -> URL {
        projectsRootURL.appendingPathComponent("\(id.uuidString).\(packageExtension)", isDirectory: true)
    }
}
