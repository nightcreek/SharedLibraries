import Foundation

public protocol ProjectStore {
    func listProjects() throws -> [RecentProject]
    func createProject(metadata: ProjectMetadata, document: EMathicaDocument) throws -> RecentProject
    func loadProject(id: UUID) throws -> EMathicaDocument
    func saveProject(_ document: EMathicaDocument) throws
    func deleteProject(id: UUID) throws
    func renameProject(id: UUID, title: String) throws -> RecentProject
    func previewURL(for id: UUID) -> URL?
}
