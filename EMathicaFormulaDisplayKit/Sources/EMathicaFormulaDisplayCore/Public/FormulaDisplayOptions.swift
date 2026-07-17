import Foundation

public struct FormulaDisplayOptions: Equatable, Sendable {
    public var debugFramesEnabled: Bool
    public var cursorVisible: Bool
    public var renderingBackend: FormulaRenderingBackend
    public var fontRole: FormulaFontRole

    public init(
        debugFramesEnabled: Bool = false,
        cursorVisible: Bool = true,
        renderingBackend: FormulaRenderingBackend = .legacy,
        fontRole: FormulaFontRole = .standard
    ) {
        self.debugFramesEnabled = debugFramesEnabled
        self.cursorVisible = cursorVisible
        self.renderingBackend = renderingBackend
        self.fontRole = fontRole
    }

    public static let `default` = FormulaDisplayOptions()
}
