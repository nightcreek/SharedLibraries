import EMathicaMathInputCore
import SwiftUI

/// Uses FormulaDisplay as the visible rendering surface while preserving the
/// existing FormulaEditorView interaction layer for cursor hit-testing and
/// hardware keyboard capture.
public struct FormulaEditingDisplayView: View {
    public static let minimumLayoutHeight: CGFloat = 44

    public let inputState: FormulaInputState
    public let isFocused: Bool
    public let configuration: FormulaRenderingConfiguration
    public let onTapCursor: (EditorCursor) -> Void
    public let onKeyboardAction: (KeyboardAction) -> Void

    public init(
        inputState: FormulaInputState,
        isFocused: Bool,
        configuration: FormulaRenderingConfiguration = .default,
        onTapCursor: @escaping (EditorCursor) -> Void,
        onKeyboardAction: @escaping (KeyboardAction) -> Void
    ) {
        self.inputState = inputState
        self.isFocused = isFocused
        self.configuration = configuration
        self.onTapCursor = onTapCursor
        self.onKeyboardAction = onKeyboardAction
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            FormulaDisplayPreviewView(
                inputState: inputState,
                configuration: configuration,
                surface: .editorPreview,
                usesInternalScrollView: false,
                showsCursor: isFocused,
                onTapCursor: onTapCursor
            )
            .overlay(alignment: .topLeading) {
                FormulaEditorView(
                    editorState: inputState.editorState,
                    isFocused: isFocused,
                    usesInternalScrollView: false,
                    interactionOverlayOnly: true,
                    onTapCursor: onTapCursor,
                    onKeyboardAction: onKeyboardAction
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
            }
        }
        .frame(minHeight: Self.minimumLayoutHeight, alignment: .topLeading)
    }
}
