import EMathicaMathInputCore
import EMathicaThemeKit
import EMathicaMathCore
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct WorkspaceObjectRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let object: MathObject
    public let allObjects: [MathObject]
    public let isSelected: Bool
    public let onTap: () -> Void
    public let onToggleVisibility: () -> Void
    public let onDelete: () -> Void
    public let onEditExpression: () -> Void
    public let onOpenSettings: () -> Void
    public let onConvertToStatic: () -> Void
    public let onUpdateStyle: (MathStyle) -> Void
    public let onDerivative: (() -> Void)?
    public let onFindRoots: (() -> Void)?
    public let semanticIntentAdapter: (any SemanticIntentAdapterProtocol)?
    public let geometryResolver: any GeometryPresentationResolverProtocol

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggleVisibility) {
                visibilityDot
            }
            .buttonStyle(.plain)
            .accessibilityLabel(object.isVisible ? "隐藏对象" : "显示对象")
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                onOpenSettings()
            })

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 0) {
                    Text(object.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)

                    Text("：")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(primaryText.opacity(0.86))

                    FormulaCompactReadOnlyView(
                        editorState: primaryExpressionEditorState,
                        fallbackText: primaryExpressionText,
                        allowsMultiline: allowsMultilineFormula,
                        minHeight: formulaMinHeight,
                        tint: primaryText.opacity(object.isVisible ? 1 : 0.56)
                    )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onEditExpression)
                }

                Text(secondaryText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary.opacity(object.isVisible ? 1 : 0.7))
                    .lineLimit(3)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                if let presentation = rowDiagnosticPresentation {
                    Image(systemName: rowDiagnosticIconName(for: presentation.severity))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(rowDiagnosticColor(for: presentation.severity))
                        .accessibilityLabel(presentation.message)
                }

                moreMenu
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(selectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onTap)
    }

    private var objectColor: Color {
        ColorToken.resolvedColor(from: object.style.colorToken)
    }

    @ViewBuilder
    private var visibilityDot: some View {
        Circle()
            .fill(object.isVisible ? objectColor : Color.clear)
            .frame(width: 11, height: 11)
            .overlay {
                Circle()
                    .stroke(objectColor.opacity(object.isVisible ? 0.95 : 0.72), lineWidth: object.isVisible ? 1 : 1.6)
            }
            .opacity(object.isVisible ? 1 : 0.72)
            .padding(.top, 5)
            .frame(width: 24, height: 24, alignment: .top)
    }

    private var moreMenu: some View {
        Menu {
            Button {
                onEditExpression()
            } label: {
                Label("编辑表达式", systemImage: "pencil")
            }

            Button {
                copyToPasteboard(primaryExpressionText)
            } label: {
                Label("复制表达式", systemImage: "doc.on.doc")
            }

            Button {
                copyToPasteboard(simplifiedExpressionText)
            } label: {
                Label("复制化简式", systemImage: "function")
            }

            Button {
                onOpenSettings()
            } label: {
                Label("打开对象设置", systemImage: "slider.horizontal.3")
            }

            if object.type == .function {
                Divider()

                if let onDerivative {
                    Button {
                        onDerivative()
                    } label: {
                        Label("求导", systemImage: "function")
                    }
                }

                if let onFindRoots {
                    Button {
                        onFindRoots()
                    } label: {
                        Label("求根", systemImage: "circle.dotted.circle")
                    }
                }
            }

            Divider()

            styleMenu

            Divider()

            if object.geometryDependency != nil {
                Button {
                    onConvertToStatic()
                } label: {
                    Label("转为独立对象", systemImage: "link.badge.minus")
                }

                Divider()
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
        }
        .simultaneousGesture(TapGesture().onEnded {
            onTap()
        })
        .buttonStyle(.plain)
    }

    private var styleMenu: some View {
        Menu("样式") {
            colorPresetMenu
            opacityPresetMenu
            if supportsLineStyling {
                lineWidthPresetMenu
                lineStylePresetMenu
            }
            if supportsPointSizing {
                pointSizePresetMenu
            }
        }
    }

    private var colorPresetMenu: some View {
        Menu("颜色") {
            ForEach(MathStylePresetProvider.colorPresets, id: \.token) { preset in
                styleButton(
                    title: preset.title,
                    selected: MathStylePresetMatcher.colorMatches(object.style, preset.token)
                ) {
                    var style = object.style
                    style.colorToken = preset.token.rawValue
                    onUpdateStyle(style)
                }
            }
        }
    }

    private var lineWidthPresetMenu: some View {
        Menu("线宽") {
            ForEach(MathStylePresetProvider.lineWidthPresets, id: \.value) { preset in
                styleButton(
                    title: preset.title,
                    selected: MathStylePresetMatcher.lineWidthMatches(object.style, preset.value)
                ) {
                    var style = object.style
                    style.lineWidth = preset.value
                    onUpdateStyle(style)
                }
            }
        }
    }

    private var opacityPresetMenu: some View {
        Menu("透明度") {
            ForEach(MathStylePresetProvider.opacityPresets, id: \.value) { preset in
                styleButton(
                    title: preset.title,
                    selected: MathStylePresetMatcher.opacityMatches(object.style, preset.value)
                ) {
                    var style = object.style
                    style.opacity = preset.value
                    onUpdateStyle(style)
                }
            }
        }
    }

    private var pointSizePresetMenu: some View {
        Menu("点大小") {
            ForEach(MathStylePresetProvider.pointSizePresets, id: \.value) { preset in
                styleButton(
                    title: preset.title,
                    selected: MathStylePresetMatcher.pointSizeMatches(object.style, preset.value)
                ) {
                    var style = object.style
                    style.pointSize = preset.value
                    onUpdateStyle(style)
                }
            }
        }
    }

    private var lineStylePresetMenu: some View {
        Menu("线型") {
            ForEach(MathStylePresetProvider.lineStylePresets, id: \.value) { preset in
                styleButton(title: preset.title, selected: MathStylePresetMatcher.lineStyleMatches(object.style, preset.value)) {
                    var style = object.style
                    style.lineStyle = preset.value
                    onUpdateStyle(style)
                }
            }
        }
    }

    private func styleButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if selected {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
    }

    private var primaryExpressionText: String {
        WorkspaceObjectExpressionDisplayResolver.primaryText(for: object)
    }

    private var primaryExpressionEditorState: EditorState? {
        if let astData = object.expression.editorASTData?.data(using: .utf8),
           let ast = try? JSONDecoder().decode(EditorState.self, from: astData) {
            return ast
        }
        if let source = object.expression.sourceExpression, !source.isEmpty,
           let root = SimpleMathParser().parseSource(source) {
            let offset: Int
            if case .sequence(let nodes) = root {
                offset = nodes.count
            } else {
                offset = 1
            }
            return EditorState(root: root, cursor: EditorCursor(path: [], offset: offset))
        }
        return nil
    }

    private var simplifiedExpressionText: String {
        object.expression.simplifiedDisplayText ?? object.expression.displayText
    }

    private var formulaMinHeight: CGFloat {
        WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: object.expression.semanticGraphKind,
            editorState: primaryExpressionEditorState,
            fallbackText: primaryExpressionText
        )
    }

    private var allowsMultilineFormula: Bool {
        WorkspaceObjectRowLayoutMetrics.allowsMultilineFormula(
            semanticGraphKind: object.expression.semanticGraphKind,
            editorState: primaryExpressionEditorState,
            fallbackText: primaryExpressionText
        )
    }

    private var secondaryText: String {
        GeometryDependencyPresentation.secondaryText(
            for: object,
            objects: allObjects,
            simplifiedText: prioritizedSimplifiedText,
            metadataText: metadataText,
            typeFallback: GeometryDependencyPresentation.objectTypeFallbackLabel(for: object),
            geometryResolver: geometryResolver
        )
    }

    private var prioritizedSimplifiedText: String? {
        guard let simplified = object.expression.simplifiedDisplayText else { return nil }
        guard simplified != object.expression.originalLatex,
              simplified != object.expression.displayText,
              simplified != primaryExpressionText else {
            return nil
        }
        return simplified
    }

    private var metadataText: String? {
        if let kind = object.geometryDefinition?.kind {
            switch kind {
            case .point3D, .segment3D, .line3D, .plane3D:
                return nil
            case .point, .segment, .line, .ray, .circle, .arc:
                break
            }
        }
        return semanticIntentAdapter?.metadataText(
            semanticGraphKind: object.expression.semanticGraphKind,
            semanticParameterSymbol: object.expression.semanticParameterSymbol,
            semanticParameterRange: object.expression.semanticParameterRange,
            algebraAnalysis: object.expression.algebraAnalysis
        )
    }

    private var supportsLineStyling: Bool {
        switch object.type {
        case .function, .circle, .segment, .line, .ray, .arc:
            return true
        default:
            return false
        }
    }

    private var supportsPointSizing: Bool {
        object.type == .point
    }

    private var rowDiagnosticPresentation: FormulaDiagnosticPresentation? {
        guard let diagnostics = object.expression.algebraAnalysis?.diagnostics else {
            return nil
        }
        return FormulaDiagnosticPresenter.topPresentation(from: diagnostics, includeInfo: false)
    }

    private func rowDiagnosticIconName(for severity: FormulaPlotDiagnosticSeverity) -> String {
        switch severity {
        case .error:
            return "xmark.octagon.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    private func rowDiagnosticColor(for severity: FormulaPlotDiagnosticSeverity) -> Color {
        switch severity {
        case .error:
            return .red.opacity(0.86)
        case .warning:
            return .orange.opacity(0.86)
        case .info:
            return .secondary
        }
    }

    private func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.accentColor.opacity(colorScheme == .dark ? WorkspaceObjectRowVisualMetrics.selectedFillDarkOpacity : WorkspaceObjectRowVisualMetrics.selectedFillLightOpacity))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.accentColor.opacity(colorScheme == .dark ? WorkspaceObjectRowVisualMetrics.selectedStrokeDarkOpacity : WorkspaceObjectRowVisualMetrics.selectedStrokeLightOpacity), lineWidth: 0.9)
                }
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(WorkspaceObjectRowVisualMetrics.unselectedFillDarkOpacity) : Color.white.opacity(WorkspaceObjectRowVisualMetrics.unselectedFillLightOpacity))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? WorkspaceObjectRowVisualMetrics.unselectedStrokeDarkOpacity : WorkspaceObjectRowVisualMetrics.unselectedStrokeLightOpacity), lineWidth: 0.6)
                }
        }
    }

}

public enum WorkspaceObjectRowVisualMetrics {
    public static let selectedFillDarkOpacity: Double = 0.12
    public static let selectedFillLightOpacity: Double = 0.05
    public static let selectedStrokeDarkOpacity: Double = 0.25
    public static let selectedStrokeLightOpacity: Double = 0.08
    public static let unselectedFillDarkOpacity: Double = 0.016
    public static let unselectedFillLightOpacity: Double = 0.045
    public static let unselectedStrokeDarkOpacity: Double = 0.04
    public static let unselectedStrokeLightOpacity: Double = 0.06
}

public enum WorkspaceObjectRowLayoutMetrics {
    public static func formulaMinHeight(
        semanticGraphKind: SemanticGraphKind?,
        editorState: EditorState?,
        fallbackText: String
    ) -> CGFloat {
        let rows = piecewiseRows(
            semanticGraphKind: semanticGraphKind,
            editorState: editorState,
            fallbackText: fallbackText
        )
        guard rows > 0 else { return 24 }
        return 24 + CGFloat(max(0, rows - 1)) * 16
    }

    public static func allowsMultilineFormula(
        semanticGraphKind: SemanticGraphKind?,
        editorState: EditorState?,
        fallbackText: String
    ) -> Bool {
        piecewiseRows(
            semanticGraphKind: semanticGraphKind,
            editorState: editorState,
            fallbackText: fallbackText
        ) > 0
    }

    private static func piecewiseRows(
        semanticGraphKind: SemanticGraphKind?,
        editorState: EditorState?,
        fallbackText: String
    ) -> Int {
        if let editorState, let rows = piecewiseRows(in: editorState.root) {
            return rows
        }
        if semanticGraphKind == .piecewise {
            let lineCount = fallbackText.split(separator: "\n", omittingEmptySubsequences: false).count
            if lineCount >= 2 { return lineCount }
            return 2
        }
        return 0
    }

    private static func piecewiseRows(in node: MathNode) -> Int? {
        switch node {
        case .template(let template):
            if case .piecewise(let rows) = template.kind {
                return rows
            }
            for field in template.fields {
                if let rows = piecewiseRows(in: field.node) {
                    return rows
                }
            }
            return nil
        case .sequence(let nodes):
            for child in nodes {
                if let rows = piecewiseRows(in: child) {
                    return rows
                }
            }
            return nil
        default:
            return nil
        }
    }
}

private struct FormulaCompactReadOnlyView: View {
    public let editorState: EditorState?
    public let fallbackText: String
    public let allowsMultiline: Bool
    public let minHeight: CGFloat
    public let tint: Color

    public var body: some View {
        Group {
            if let editorState {
                FormulaEditorView(
                    editorState: editorState,
                    isFocused: false,
                    onTapCursor: { _ in },
                    onKeyboardAction: { _ in }
                )
                .scaleEffect(WorkspaceObjectFormulaDisplayMetrics.scaleFactor(allowsMultiline: allowsMultiline), anchor: .topLeading)
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
                .allowsHitTesting(false)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(fallbackText)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .multilineTextAlignment(.leading)
                        .frame(minHeight: minHeight, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            }
        }
        .foregroundStyle(tint)
    }
}

public enum WorkspaceObjectExpressionDisplayResolver {
    public static func primaryText(for object: MathObject) -> String {
        if let displayText = nonEmptyText(object.expression.displayText) {
            return displayText
        }
        if let originalLatex = nonEmptyText(object.expression.originalLatex) {
            return originalLatex
        }
        if let raw = nonEmptyText(object.expression.rawInput) {
            return raw
        }
        return object.name
    }

    private static func nonEmptyText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : text
    }
}

public enum WorkspaceObjectFormulaDisplayMetrics {
    public static func scaleFactor(allowsMultiline: Bool) -> CGFloat {
        allowsMultiline ? 0.68 : 0.62
    }

    public static func fallbackLineLimit(allowsMultiline: Bool, fallbackText: String) -> Int {
        _ = allowsMultiline
        _ = fallbackText
        return 1
    }
}
