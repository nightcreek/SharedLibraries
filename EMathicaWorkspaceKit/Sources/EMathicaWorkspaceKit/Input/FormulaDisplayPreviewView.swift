import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import SwiftUI

/// Read-only preview bridge from WorkspaceKit's existing FormulaInputState snapshots
/// into the standalone FormulaDisplay renderer.
public struct FormulaDisplayPreviewView: View {
    private let document: FormulaDisplayDocument?
    private let rawValue: String?
    private let fallbackText: String
    private let configuration: FormulaRenderingConfiguration
    private let surface: FormulaDisplaySurface
    private let minHeight: CGFloat
    private let usesInternalScrollView: Bool

    public init(
        rawValue: String,
        fallbackText: String = "",
        configuration: FormulaRenderingConfiguration = .default,
        surface: FormulaDisplaySurface = .editorPreview,
        minHeight: CGFloat = FormulaEditingDisplayView.minimumLayoutHeight,
        usesInternalScrollView: Bool = true
    ) {
        self.document = nil
        self.rawValue = rawValue
        self.fallbackText = fallbackText
        self.configuration = configuration
        self.surface = surface
        self.minHeight = minHeight
        self.usesInternalScrollView = usesInternalScrollView
    }

    public init(
        inputState: FormulaInputState,
        configuration: FormulaRenderingConfiguration = .default,
        surface: FormulaDisplaySurface = .editorPreview,
        usesInternalScrollView: Bool = true
    ) {
        self.document = inputState.displayDocumentSnapshot
        self.rawValue = nil
        self.fallbackText = inputState.latexOutputSnapshot
        self.configuration = configuration
        self.surface = surface
        self.minHeight = FormulaEditingDisplayView.minimumLayoutHeight
        self.usesInternalScrollView = usesInternalScrollView
    }

    public var body: some View {
        switch resolvedMode {
        case .plainText(let text, _):
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyView()
            } else {
                scrollWrappedIfNeeded {
                    Text(text)
                        .font(.system(size: Self.previewFontSize, weight: .medium, design: .serif))
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        case .formula(let resolvedDocument, let resolvedRawValue, let options, _):
            scrollWrappedIfNeeded {
                Group {
                    if let resolvedDocument {
                        FormulaDisplayView(
                            document: resolvedDocument,
                            style: formulaStyle,
                            options: options,
                            metrics: FormulaReadOnlyDisplayResolver.makeMetrics(
                                surface: surface,
                                fontSize: Self.previewFontSize,
                                minHeight: minHeight
                            )
                        )
                    } else {
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
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    @MainActor
    private var resolvedMode: FormulaReadOnlyDisplayResolvedMode {
        if let document {
            return FormulaReadOnlyDisplayResolver.resolve(
                surface: surface,
                document: document,
                fallbackText: fallbackText,
                fontSize: Self.previewFontSize,
                minHeight: minHeight,
                allowsMultiline: false,
                configuration: configuration
            )
        }

        return FormulaReadOnlyDisplayResolver.resolve(
            surface: surface,
            rawValue: rawValue ?? "",
            fallbackText: fallbackText,
            fontSize: Self.previewFontSize,
            minHeight: minHeight,
            allowsMultiline: false,
            configuration: configuration
        )
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

    @ViewBuilder
    private func scrollWrappedIfNeeded<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if usesInternalScrollView {
            ScrollView(.horizontal, showsIndicators: false) {
                content()
            }
        } else {
            content()
        }
    }

    private static let previewFontSize: CGFloat = 22
}
