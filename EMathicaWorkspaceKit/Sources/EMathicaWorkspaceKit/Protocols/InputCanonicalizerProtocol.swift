import EMathicaMathCore
import Foundation

/// Canonicalizes raw user input before it is parsed/built into a
/// `MathExpression`. Different modules have different canonical forms
/// (e.g. Plane rewrites explicit-y as "y=expr", Space may use 3D
/// coordinate conventions).
public protocol InputCanonicalizerProtocol: Sendable {

    /// Transform the trimmed user input into the module's canonical form.
    /// - Parameter source: Raw trimmed input string
    /// - Parameter semanticState: The current semantic analysis state
    /// - Returns: Canonicalized input string for the module's expression builder
    func canonicalize(
        source: String,
        semanticState: FormulaSemanticState
    ) -> String
}
