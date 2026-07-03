import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import SwiftUI

/// Read-only preview bridge from WorkspaceKit's existing FormulaInputState snapshots
/// into the standalone FormulaDisplay renderer.
public struct FormulaDisplayPreviewView: View {
    private let rawValue: String
    private let fallbackText: String

    public init(rawValue: String, fallbackText: String = "") {
        self.rawValue = rawValue
        self.fallbackText = fallbackText
    }

    public init(inputState: FormulaInputState) {
        self.rawValue = inputState.displayMarkupSnapshot.rawValue
        self.fallbackText = inputState.displayLatex
    }

    public var body: some View {
        if rawValue.isEmpty {
            if fallbackText.isEmpty {
                EmptyView()
            } else {
                Text(fallbackText)
            }
        } else {
            FormulaDisplayView(rawValue: rawValue)
        }
    }
}
