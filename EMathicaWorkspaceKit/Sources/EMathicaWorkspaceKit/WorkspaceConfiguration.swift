import Foundation

public struct WorkspaceConfiguration: Hashable {
    public var module: CalculatorModuleType
    public var moduleProvider: WorkspaceModuleProviding
    public var toolGroups: [WorkspaceToolGroup]
    public var showsObjectPanel: Bool
    public var showsInputBar: Bool
    public var showsInspectorButton: Bool
    public var showsMathKeyboard: Bool

    public init(
        module: CalculatorModuleType,
        moduleProvider: WorkspaceModuleProviding,
        toolGroups: [WorkspaceToolGroup],
        showsObjectPanel: Bool = true,
        showsInputBar: Bool = true,
        showsInspectorButton: Bool = true,
        showsMathKeyboard: Bool = false
    ) {
        self.module = module
        self.moduleProvider = moduleProvider
        self.toolGroups = toolGroups
        self.showsObjectPanel = showsObjectPanel
        self.showsInputBar = showsInputBar
        self.showsInspectorButton = showsInspectorButton
        self.showsMathKeyboard = showsMathKeyboard
    }

}

public extension WorkspaceConfiguration {
    public static func == (lhs: WorkspaceConfiguration, rhs: WorkspaceConfiguration) -> Bool {
        lhs.module == rhs.module &&
        lhs.toolGroups == rhs.toolGroups &&
        lhs.showsObjectPanel == rhs.showsObjectPanel &&
        lhs.showsInputBar == rhs.showsInputBar &&
        lhs.showsInspectorButton == rhs.showsInspectorButton &&
        lhs.showsMathKeyboard == rhs.showsMathKeyboard
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(module)
        hasher.combine(toolGroups)
        hasher.combine(showsObjectPanel)
        hasher.combine(showsInputBar)
        hasher.combine(showsInspectorButton)
        hasher.combine(showsMathKeyboard)
    }
}
