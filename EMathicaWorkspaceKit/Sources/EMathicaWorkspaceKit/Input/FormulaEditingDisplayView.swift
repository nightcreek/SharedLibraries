import EMathicaMathInputCore
import SwiftUI

/// Uses FormulaDisplay as the visible rendering surface while preserving the
/// existing FormulaEditorView interaction layer for cursor hit-testing and
/// hardware keyboard capture.
public struct FormulaEditingDisplayView: View {
    public let inputState: FormulaInputState
    public let isFocused: Bool
    public let onTapCursor: (EditorCursor) -> Void
    public let onKeyboardAction: (KeyboardAction) -> Void

    public init(
        inputState: FormulaInputState,
        isFocused: Bool,
        onTapCursor: @escaping (EditorCursor) -> Void,
        onKeyboardAction: @escaping (KeyboardAction) -> Void
    ) {
        self.inputState = inputState
        self.isFocused = isFocused
        self.onTapCursor = onTapCursor
        self.onKeyboardAction = onKeyboardAction
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            FormulaDisplayPreviewView(inputState: inputState)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            FormulaEditorView(
                editorState: inputState.editorState,
                isFocused: isFocused,
                onTapCursor: onTapCursor,
                onKeyboardAction: onKeyboardAction
            )
            .opacity(0.015)
        }
    }
}
