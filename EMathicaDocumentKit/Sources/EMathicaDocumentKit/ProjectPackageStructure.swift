import Foundation

public struct ProjectPackageStructure: Hashable, Codable, Sendable {
    public var projectJSONPath: String
    public var assetsPath: String
    public var previewPNGPath: String
    public var notebookJSONPath: String
    public var graphsPath: String
    public var pluginsPath: String

    public static let `default` = ProjectPackageStructure(
        projectJSONPath: "project.json",
        assetsPath: "assets/",
        previewPNGPath: "preview.png",
        notebookJSONPath: "notebook.json",
        graphsPath: "graphs/",
        pluginsPath: "plugins/"
    )
}
