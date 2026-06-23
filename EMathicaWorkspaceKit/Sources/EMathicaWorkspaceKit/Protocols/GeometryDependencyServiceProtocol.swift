import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

/// Resolves geometric dependency chains — recomputes derived objects when
/// their source objects change. Each calculator module (Plane/Space) provides
/// its own implementation.
///
/// Modules without geometry construction support return `nil` from
/// `WorkspaceModuleProviding.geometryDependencyService`.
public protocol GeometryDependencyServiceProtocol: Sendable {

    /// Find objects that directly reference any of the candidate source IDs
    /// via their `geometryDependency`.
    func directlyAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID>

    /// Find all objects transitively affected by walking the dependency chain.
    func downstreamAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID>

    /// Produce `DocumentObjectPatch` values for derived objects whose source
    /// objects changed. Returns `[(objectID, patch)]`.
    func dependencyPatches(
        objects: [MathObject],
        changedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)]

    /// Produce patches that clear geometry state when source objects are
    /// deleted.
    func dependencyCleanupPatchesForRemovedSources(
        objects: [MathObject],
        removedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)]
}
