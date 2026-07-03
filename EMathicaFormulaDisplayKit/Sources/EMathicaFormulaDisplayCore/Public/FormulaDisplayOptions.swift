import Foundation

public struct FormulaDisplayOptions: Equatable, Sendable {
    public var debugFramesEnabled: Bool
    public var cursorVisible: Bool

    public init(
        debugFramesEnabled: Bool = false,
        cursorVisible: Bool = true
    ) {
        self.debugFramesEnabled = debugFramesEnabled
        self.cursorVisible = cursorVisible
    }

    public static let `default` = FormulaDisplayOptions()
}
