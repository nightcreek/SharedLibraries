import Foundation
import EMathicaDocumentKit

public struct ModuleCommandContext: Hashable {
    public var document: EMathicaDocument
    public var selectedObjectIDs: Set<UUID>
    public var inputText: String
}

public enum WorkspaceEffect: Hashable {
    case selectObject(id: UUID)
    case selectObjects(Set<UUID>)
    case clearSelection

    case setActiveTool(id: String)

    case openInput(mode: WorkspaceInputMode)
    case closeInput
    case focusInput

    case showKeyboard(Bool)
    case showInspector(Bool)

    case showError(String)
    case showToast(String)
}

public struct ModuleCommandOutput: Hashable {
    var documentCommands: [DocumentCommand]
    var effects: [WorkspaceEffect]

    public init(documentCommands: [DocumentCommand] = [], effects: [WorkspaceEffect] = []) {
        self.documentCommands = documentCommands
        self.effects = effects
    }
}

public protocol ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput
}
