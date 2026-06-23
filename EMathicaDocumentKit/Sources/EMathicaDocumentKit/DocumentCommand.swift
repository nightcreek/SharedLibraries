import Foundation
import EMathicaMathCore

public enum DocumentCommand: Hashable {
    case addObject(MathObject)

    case updateObject(id: UUID, patch: DocumentObjectPatch)

    case deleteObject(id: UUID)
    case deleteObjects([UUID])

    case renameObject(id: UUID, name: String)

    case setObjectVisibility(id: UUID, isVisible: Bool)

    case reorderObject(id: UUID, toIndex: Int)

    case updateCanvasState(CanvasState)
    case updateSpaceCameraState(SpaceCameraState?)

    case updateMetadata(ProjectMetadata)

    case appendDeletedObjectRecords([DeletedObjectRecord])
    case removeDeletedObjectRecord(recordID: UUID)
}
