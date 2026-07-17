import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import SwiftUI

/// Read-only preview bridge from WorkspaceKit's existing FormulaInputState snapshots
/// into the standalone FormulaDisplay renderer.
public struct FormulaDisplayPreviewView: View {
    private let rawValue: String
    private let fallbackText: String
    private let configuration: FormulaRenderingConfiguration
    private let surface: FormulaDisplaySurface
    private let minHeight: CGFloat

    public init(
        rawValue: String,
        fallbackText: String = "",
        configuration: FormulaRenderingConfiguration = .default,
        surface: FormulaDisplaySurface = .editorPreview,
        minHeight: CGFloat = FormulaEditorView.preferredHeight(for: EditorState())
    ) {
        self.rawValue = rawValue
        self.fallbackText = fallbackText
        self.configuration = configuration
        self.surface = surface
        self.minHeight = minHeight
    }

    public init(
        inputState: FormulaInputState,
        configuration: FormulaRenderingConfiguration = .default,
        surface: FormulaDisplaySurface = .editorPreview
    ) {
        self.rawValue = inputState.displayMarkupSnapshot.rawValue
        self.fallbackText = inputState.displayLatex
        self.configuration = configuration
        self.surface = surface
        self.minHeight = FormulaEditorView.preferredHeight(for: inputState.editorState)
    }

    public var body: some View {
        switch FormulaReadOnlyDisplayResolver.resolve(
            surface: surface,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: Self.previewFontSize,
            minHeight: minHeight,
            allowsMultiline: false,
            configuration: configuration
        ) {
        case .plainText(let text, _):
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.system(size: Self.previewFontSize, weight: .medium, design: .serif))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        case .formula(let resolvedRawValue, let options, _):
            ScrollView(.horizontal, showsIndicators: false) {
                FormulaDisplayView(
                    rawValue: resolvedRawValue,
                    style: formulaStyle,
                    options: options,
                    metrics: FormulaReadOnlyDisplayResolver.makeMetrics(
                        surface: surface,
                        fontSize: Self.previewFontSize,
                        minHeight: minHeight
                    )
                )
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var formulaStyle: FormulaDisplayStyle {
        FormulaDisplayStyle(
            textColor: .primary,
            operatorColor: .primary,
            functionColor: .primary,
            rawTextColor: .primary,
            errorTextColor: Color.primary.opacity(0.76),
            cursorColor: .primary,
            placeholderStrokeColor: Color.primary.opacity(0.75),
            placeholderFillColor: .clear,
            fractionLineColor: .primary,
            radicalColor: .primary,
            delimiterColor: .primary,
            debugColor: .clear,
            baseFont: .system(size: Self.previewFontSize, weight: .medium, design: .serif),
            scriptScale: 0.66
        )
    }

    private static let previewFontSize: CGFloat = 22
}
