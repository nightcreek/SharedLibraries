import EMathicaFormulaDisplayCore
import Foundation

public enum FormulaDisplaySurface: String, Hashable, Sendable {
    case objectPanel
    case inspector
    case editorPreview
    case notebook
    case export
}

public struct FormulaRenderingConfiguration: Hashable, Sendable {
    public var backend: FormulaRenderingBackend
    public var fontRole: FormulaFontRole

    public init(
        backend: FormulaRenderingBackend = .legacy,
        fontRole: FormulaFontRole = .standard
    ) {
        self.backend = backend
        self.fontRole = fontRole
    }

    public static let `default` = FormulaRenderingConfiguration()
}

public typealias ObjectPanelFormulaDisplayConfiguration = FormulaRenderingConfiguration
