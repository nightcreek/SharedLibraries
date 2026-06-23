import EMathicaDocumentKit
import EMathicaMathCore
import Foundation
import CoreGraphics

public struct WorkspaceToolContext: Hashable {
    public var module: CalculatorModuleType
    public var document: EMathicaDocument
    public var selectedObjectIDs: Set<UUID>
    public var selectedToolID: String?
    public var inputText: String
    public var canvasSize: CGSize?
    public var worldPoint: WorldPoint?
    public var hitObjectID: UUID?
}

