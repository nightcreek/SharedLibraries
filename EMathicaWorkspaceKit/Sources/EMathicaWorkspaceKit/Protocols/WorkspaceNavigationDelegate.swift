import EMathicaDocumentKit
import Foundation

/// Navigation actions that the workspace can request from the hosting app.
/// The hosting app (or CoreHome) implements this and injects it via the
/// SwiftUI environment.
///
/// This replaces the direct dependency on `AppNavigationState`.
@MainActor
public protocol WorkspaceNavigationDelegate: AnyObject {

    /// Called when the user wants to close the workspace and return home.
    /// The delegate is responsible for saving the document if needed.
    func workspaceDidRequestClose(document: EMathicaDocument)

    /// Called when the user renames the project.
    /// - Returns: The updated project metadata.
    func workspaceDidRenameProject(id: UUID, title: String) throws -> RecentProject
}
