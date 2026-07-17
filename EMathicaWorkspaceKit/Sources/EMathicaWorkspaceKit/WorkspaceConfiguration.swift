import Foundation
import EMathicaFormulaDisplayCore

public struct WorkspaceConfiguration: Hashable {
    public var module: CalculatorModuleType
    public var moduleProvider: WorkspaceModuleProviding
    public var toolGroups: [WorkspaceToolGroup]
    public var showsObjectPanel: Bool
    public var showsInputBar: Bool
    public var showsInspectorButton: Bool
    public var showsMathKeyboard: Bool
    public var readOnlyFormulaDisplay: FormulaRenderingConfiguration

    public init(
        module: CalculatorModuleType,
        moduleProvider: WorkspaceModuleProviding,
        toolGroups: [WorkspaceToolGroup],
        showsObjectPanel: Bool = true,
        showsInputBar: Bool = true,
        showsInspectorButton: Bool = true,
        showsMathKeyboard: Bool = false,
        readOnlyFormulaDisplay: FormulaRenderingConfiguration = .default
    ) {
        self.module = module
        self.moduleProvider = moduleProvider
        self.toolGroups = toolGroups
        self.showsObjectPanel = showsObjectPanel
        self.showsInputBar = showsInputBar
        self.showsInspectorButton = showsInspectorButton
        self.showsMathKeyboard = showsMathKeyboard
        self.readOnlyFormulaDisplay = readOnlyFormulaDisplay
    }

    public init(
        module: CalculatorModuleType,
        moduleProvider: WorkspaceModuleProviding,
        toolGroups: [WorkspaceToolGroup],
        showsObjectPanel: Bool = true,
        showsInputBar: Bool = true,
        showsInspectorButton: Bool = true,
        showsMathKeyboard: Bool = false,
        objectPanelFormulaDisplay: FormulaRenderingConfiguration
    ) {
        self.init(
            module: module,
            moduleProvider: moduleProvider,
            toolGroups: toolGroups,
            showsObjectPanel: showsObjectPanel,
            showsInputBar: showsInputBar,
            showsInspectorButton: showsInspectorButton,
            showsMathKeyboard: showsMathKeyboard,
            readOnlyFormulaDisplay: objectPanelFormulaDisplay
        )
    }

    public var objectPanelFormulaDisplay: FormulaRenderingConfiguration {
        get { readOnlyFormulaDisplay }
        set { readOnlyFormulaDisplay = newValue }
    }
}

public extension WorkspaceConfiguration {
    public static func == (lhs: WorkspaceConfiguration, rhs: WorkspaceConfiguration) -> Bool {
        lhs.module == rhs.module &&
        lhs.toolGroups == rhs.toolGroups &&
        lhs.showsObjectPanel == rhs.showsObjectPanel &&
        lhs.showsInputBar == rhs.showsInputBar &&
        lhs.showsInspectorButton == rhs.showsInspectorButton &&
        lhs.showsMathKeyboard == rhs.showsMathKeyboard &&
        lhs.readOnlyFormulaDisplay == rhs.readOnlyFormulaDisplay
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(module)
        hasher.combine(toolGroups)
        hasher.combine(showsObjectPanel)
        hasher.combine(showsInputBar)
        hasher.combine(showsInspectorButton)
        hasher.combine(showsMathKeyboard)
        hasher.combine(readOnlyFormulaDisplay)
    }
}
