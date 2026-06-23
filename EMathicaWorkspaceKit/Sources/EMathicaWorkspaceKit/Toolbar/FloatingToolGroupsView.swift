import SwiftUI

public struct FloatingToolGroupsView: View {
    public let toolGroups: [WorkspaceToolGroup]
    public let selectedToolID: String?
    public let onToolAction: (WorkspaceToolAction) -> Void

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(toolGroups) { group in
                ToolGroupCapsuleView(group: group, selectedToolID: selectedToolID, onToolAction: onToolAction)
            }
        }
        .padding(.horizontal, 6)
    }
}
