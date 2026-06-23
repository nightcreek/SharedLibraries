import EMathicaMathCore
import Foundation

/// Default identity canonicalizer — returns the source unchanged.
/// Used by modules that don't have custom input canonicalization.
public struct DefaultInputCanonicalizer: InputCanonicalizerProtocol {
    public init() {}
    public func canonicalize(
        source: String,
        semanticState: FormulaSemanticState
    ) -> String {
        source
    }
}
