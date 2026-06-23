import Foundation
import EMathicaMathCore

/// Bridges between the math-level `GraphIntent` and document-level
/// `SemanticGraphKind`, `Symbol`, `ParameterRange`.
///
/// Modules without graph classification support return `nil` from
/// `WorkspaceModuleProviding.semanticIntentAdapter`.
public protocol SemanticIntentAdapterProtocol: Sendable {

    /// Map a `GraphIntent` to a `SemanticGraphKind` for document storage.
    func semanticGraphKind(from intent: GraphIntent?) -> SemanticGraphKind?

    /// Extract the parameter symbol (e.g. "t" for parametric, "θ" for polar).
    func parameterSymbol(from intent: GraphIntent?) -> Symbol?

    /// Extract the parameter range (lower/upper bounds).
    func parameterRange(from intent: GraphIntent?) -> ParameterRange?

    /// Produce a human-readable metadata string for display in the object panel.
    /// Returns `nil` when no meaningful metadata can be derived.
    func metadataText(
        semanticGraphKind: SemanticGraphKind?,
        semanticParameterSymbol: Symbol?,
        semanticParameterRange: ParameterRange?,
        algebraAnalysis: AlgebraAnalysisResult?
    ) -> String?
}
