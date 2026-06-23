import Foundation
import EMathicaMathCore

public struct EMathicaDocument: Identifiable, Hashable, Codable {
    public mutating func apply(_ commands: [DocumentCommand]) {
        for command in commands {
            apply(command)
        }
    }

    public mutating func apply(_ command: DocumentCommand) {
        switch command {
        case .addObject(let object):
            objects.append(object)

        case .updateObject(let id, let patch):
            guard let index = objects.firstIndex(where: { $0.id == id }) else { return }
            var updated = objects[index]
            if let name = patch.name {
                updated.name = name
            }
            if let isVisible = patch.isVisible {
                updated.isVisible = isVisible
            }
            if let expressionDisplayText = patch.expressionDisplayText {
                updated.expression.displayText = expressionDisplayText
            }
            if let expression = patch.expression {
                updated.expression = expression
            }
            if let position = patch.position {
                updated.position = position
            }
            if let points = patch.points {
                updated.points = points
            }
            if let parameterValue = patch.parameterValue {
                updated.parameterValue = parameterValue
            }
            if let parameterMin = patch.parameterMin {
                updated.parameterMin = parameterMin
            }
            if let parameterMax = patch.parameterMax {
                updated.parameterMax = parameterMax
            }
            if let sliderSettings = patch.sliderSettings {
                updated.sliderSettings = sliderSettings
            }
            if let geometryDefinition = patch.geometryDefinition {
                updated.geometryDefinition = geometryDefinition
            }
            if patch.clearGeometryDependency == true {
                updated.geometryDependency = nil
            } else if let geometryDependency = patch.geometryDependency {
                updated.geometryDependency = geometryDependency
            }
            if patch.clearGeometryDefinitionStatus == true {
                updated.geometryDefinitionStatus = nil
            } else if let geometryDefinitionStatus = patch.geometryDefinitionStatus {
                updated.geometryDefinitionStatus = geometryDefinitionStatus
            }
            if let styleColorToken = patch.styleColorToken {
                updated.style.colorToken = styleColorToken
            }
            if let styleOpacity = patch.styleOpacity {
                updated.style.opacity = styleOpacity
            }
            if let styleFillOpacity = patch.styleFillOpacity {
                updated.style.fillOpacity = styleFillOpacity
            }
            if let styleLineWidth = patch.styleLineWidth {
                updated.style.lineWidth = styleLineWidth
            }
            if let stylePointSize = patch.stylePointSize {
                updated.style.pointSize = stylePointSize
            }
            if let styleLineStyle = patch.styleLineStyle {
                updated.style.lineStyle = styleLineStyle
            }
            updated.style.sanitizeInPlace()
            objects[index] = updated

        case .deleteObject(let id):
            objects.removeAll(where: { $0.id == id })

        case .deleteObjects(let ids):
            let idSet = Set(ids)
            objects.removeAll(where: { idSet.contains($0.id) })

        case .renameObject(let id, let name):
            guard let index = objects.firstIndex(where: { $0.id == id }) else { return }
            objects[index].name = name

        case .setObjectVisibility(let id, let isVisible):
            guard let index = objects.firstIndex(where: { $0.id == id }) else { return }
            objects[index].isVisible = isVisible

        case .reorderObject(let id, let toIndex):
            guard let fromIndex = objects.firstIndex(where: { $0.id == id }) else { return }
            let clamped = max(0, min(toIndex, objects.count - 1))
            let item = objects.remove(at: fromIndex)
            objects.insert(item, at: clamped)

        case .updateCanvasState(let newState):
            canvasState = newState

        case .updateSpaceCameraState(let newState):
            spaceCameraState = newState

        case .updateMetadata(let newMetadata):
            metadata = newMetadata

        case .appendDeletedObjectRecords(let records):
            guard !records.isEmpty else { return }
            var history = deletedObjectHistory ?? []
            history.append(contentsOf: records)
            if history.count > Self.deletedObjectHistoryLimit {
                history.removeFirst(history.count - Self.deletedObjectHistoryLimit)
            }
            deletedObjectHistory = history

        case .removeDeletedObjectRecord(let recordID):
            guard var history = deletedObjectHistory else { return }
            history.removeAll { $0.id == recordID }
            deletedObjectHistory = history.isEmpty ? nil : history
        }
    }

    public let id: UUID
    public var metadata: ProjectMetadata
    public var moduleID: String
    public var objects: [MathObject]
    public var deletedObjectHistory: [DeletedObjectRecord]?
    public var canvasState: CanvasState
    public var spaceCameraState: SpaceCameraState?
    public var packageStructure: ProjectPackageStructure

    public static let deletedObjectHistoryLimit = 200

    public init(
        id: UUID = UUID(),
        metadata: ProjectMetadata,
        moduleID: String,
        objects: [MathObject],
        deletedObjectHistory: [DeletedObjectRecord]? = nil,
        canvasState: CanvasState = .default,
        spaceCameraState: SpaceCameraState? = nil,
        packageStructure: ProjectPackageStructure = .default
    ) {
        self.id = id
        self.metadata = metadata
        self.moduleID = moduleID
        self.objects = objects
        self.deletedObjectHistory = deletedObjectHistory
        self.canvasState = canvasState
        self.spaceCameraState = spaceCameraState
        self.packageStructure = packageStructure
    }
}
