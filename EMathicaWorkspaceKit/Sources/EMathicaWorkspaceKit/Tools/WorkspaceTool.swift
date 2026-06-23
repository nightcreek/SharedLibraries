import Foundation

public struct WorkspaceTool: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var icon: WorkspaceToolIcon
    public var action: WorkspaceToolAction
    public var isEnabled: Bool
    public var accessibilityLabel: String?

    public init(
        id: String,
        title: String,
        icon: WorkspaceToolIcon,
        action: WorkspaceToolAction,
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
    }
}

