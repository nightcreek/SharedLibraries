import EMathicaMathInputCore
import Foundation

public enum FormulaEditMode: Equatable {
    case createNew
    case editExisting(objectID: UUID)
}

public struct FormulaEditSession: Equatable {
    public var mode: FormulaEditMode
    public var editorState: EditorState
    public var originalEditorState: EditorState?
    public var isDirty: Bool
}

public enum WorkspaceFocus: Equatable, Sendable {
    case none
    case formulaEditor
    case canvas
}

public struct EditorUIState: Equatable, Sendable {
    public var focus: WorkspaceFocus
    public var isMathKeyboardVisible: Bool

    public static let `default` = EditorUIState(focus: .none, isMathKeyboardVisible: false)
}
