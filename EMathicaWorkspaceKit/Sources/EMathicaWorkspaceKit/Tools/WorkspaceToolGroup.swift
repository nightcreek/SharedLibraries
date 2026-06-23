import Foundation

public struct WorkspaceToolGroup: Identifiable, Hashable {
    public init(id: String, title: String, tools: [WorkspaceTool]) { self.id = id; self.title = title; self.tools = tools }
    public let id: String
    public var title: String
    public var tools: [WorkspaceTool]

    public func selectedTool(for activeToolID: String?) -> WorkspaceTool? {
        guard let activeToolID else { return nil }
        return tools.first(where: { $0.id == activeToolID })
    }

    public func displayedTool(for activeToolID: String?) -> WorkspaceTool? {
        selectedTool(for: activeToolID) ?? tools.first
    }
}
