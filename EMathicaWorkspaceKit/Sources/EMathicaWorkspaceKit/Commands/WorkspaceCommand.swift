import EMathicaMathCore
import Foundation

public enum WorkspaceCommand: Hashable {
    case setActiveTool(id: String)

    case selectObject(id: UUID)
    case clearSelection

    case createPoint(at: WorldPoint)
    case createFunction(expression: String)
    case createSegment(start: WorldPoint, end: WorldPoint)
    case createLine(pointA: WorldPoint, pointB: WorldPoint)
    case createRay(start: WorldPoint, through: WorldPoint)

    case deleteObject(id: UUID)
    case deleteObjects(ids: [UUID])
    case deleteSelectedObjects
    case duplicateSelectedObjects

    case renameObject(id: UUID, newName: String)

    case toggleObjectVisibility(id: UUID)
    case updateObjectStyle(
        id: UUID,
        colorToken: String?,
        opacity: Double?,
        fillOpacity: Double?,
        lineWidth: Double?,
        pointSize: Double?,
        lineStyle: MathLineStyle?
    )

    case updateObjectPosition(id: UUID, position: WorldPoint)
    case setObjectDragging(id: UUID?, isDragging: Bool)
    case convertObjectToStatic(id: UUID)
    case restoreDeletedObject(recordID: UUID)

    case updateInputText(String)
    case submitInput
    case dismissInput

    case openInput(mode: WorkspaceInputMode)

    case toggleKeyboard
    case setKeyboardVisible(Bool)

    case setInspectorVisible(Bool)

    case toggleObjectPanel
    case setObjectPanelVisible(Bool)

    case setCanvasViewport(CanvasState)
    case setSpaceCameraState(SpaceCameraState)
    case setSpaceWorkPlane(SpaceWorkPlane)
    case setCanvasInteracting(Bool)

    case undo
    case redo
    case revertToOpenState

    case moduleSpecific(id: String, payload: String)
}
