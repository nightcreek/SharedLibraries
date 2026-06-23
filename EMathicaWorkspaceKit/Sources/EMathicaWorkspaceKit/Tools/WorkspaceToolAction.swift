import Foundation

public enum WorkspaceToolAction: Hashable {
    case setActiveTool(String)
    case openInput(WorkspaceInputMode)
    case showInspector
    case command(WorkspaceCommand)
    case moduleSpecific(String)
}

