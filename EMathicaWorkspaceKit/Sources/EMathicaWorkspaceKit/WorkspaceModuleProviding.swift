import EMathicaDocumentKit
import EMathicaMathCore
import SwiftUI
import CoreGraphics

public enum WorkspaceModuleBuildError: Error, Hashable {
    case message(String)

    public var message: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}

public struct WorkspaceCanvasContext {
    public var canvasState: CanvasState
    public var spaceCameraState: SpaceCameraState?
    public var spaceWorkPlane: SpaceWorkPlane?
    public var objects: [MathObject]
    public var selectedObjectID: UUID?
    public var selectedObjectIDs: Set<UUID>
    public var activeToolID: String
    public var draftMathObject: DraftMathObject?
    public var dispatch: (WorkspaceCommand) -> Void
}

public protocol WorkspaceModuleProviding {
    var module: CalculatorModuleType { get }
    var toolGroups: [WorkspaceToolGroup] { get }
    var commandHandler: ModuleCommandHandler { get }
    var startsWithObjectPanelCollapsed: Bool { get }
    var autoRevealsInspectorOnSelection: Bool { get }
    var autoHidesInspectorOnSelectionClear: Bool { get }

    func makeCanvasView(context: WorkspaceCanvasContext) -> AnyView

    /// Returns a module-specific draft preview object, or nil when the module has no draft preview support.
    func makeDraftMathObject(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        previous: DraftMathObject?,
        canvasPixelSize: CGSize?,
        canvasInteracting: Bool
    ) -> DraftMathObject?

    /// Parses/normalizes/simplifies module-specific input and returns the expression payload used for document updates.
    func buildExpression(
        from source: String,
        fallbackToExplicitY: Bool
    ) -> Result<MathExpression, WorkspaceModuleBuildError>

    // MARK: - Service Protocols

    /// Service for recomputing derived geometry objects when source objects change.
    /// Modules without geometry construction support return `nil`.
    var geometryDependencyService: (any GeometryDependencyServiceProtocol)? { get }

    /// Adapter that bridges GraphIntent to document-level semantic metadata.
    /// Modules without graph classification support return `nil`.
    var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? { get }

    /// Canonicalizes raw user input before expression building.
    /// Modules that don't need canonicalization use `DefaultInputCanonicalizer`.
    var inputCanonicalizer: any InputCanonicalizerProtocol { get }

    /// Optional module-specific object naming service.
    var objectNamingService: (any WorkspaceObjectNamingServiceProtocol)? { get }

    /// Optional module-specific resolver used by shared ObjectPanel / Inspector
    /// presentation code to derive geometry properties.
    var geometryPresentationResolver: (any GeometryPresentationResolverProtocol)? { get }

    /// Returns whether the module allows editing the expression of the given object.
    /// Modules that do not support expression editing can rely on the default `false`.
    func canEditExpression(for object: MathObject) -> Bool
}

public extension WorkspaceModuleProviding {
    var startsWithObjectPanelCollapsed: Bool { false }
    var autoRevealsInspectorOnSelection: Bool { false }
    var autoHidesInspectorOnSelectionClear: Bool { false }
    var geometryPresentationResolver: (any GeometryPresentationResolverProtocol)? { nil }
    func canEditExpression(for object: MathObject) -> Bool { false }
}
