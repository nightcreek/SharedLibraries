import EMathicaMathInputCore
import EMathicaMathCore
import EMathicaDocumentKit
import SwiftUI

public struct MathEditorHitRegion: Equatable, Identifiable {
    public enum Kind: Equatable {
        case editableSlot(role: FormulaEditorView.SlotHitRole)
        case placeholder
        case token
        case templateBody
        case formulaBody
    }

    public var id: String
    public var kind: Kind
    public var rect: CGRect
    public var cursor: EditorCursor?
    public var path: [EditorPathComponent]? = nil
    public var cursorBefore: EditorCursor? = nil
    public var cursorAfter: EditorCursor? = nil
    public var priority: Int
}

private struct MathEditorHitRegionPreferenceKey: PreferenceKey {
    static nonisolated(unsafe) var defaultValue: [MathEditorHitRegion] = []

    public static func reduce(value: inout [MathEditorHitRegion], nextValue: () -> [MathEditorHitRegion]) {
        value.append(contentsOf: nextValue())
    }
}

public struct FormulaEditorView: View {
    public var editorState: EditorState
    public var isFocused: Bool
    public var usesInternalScrollView: Bool
    public var interactionOverlayOnly: Bool
    public var onTapCursor: (EditorCursor) -> Void
    public var onKeyboardAction: (KeyboardAction) -> Void
    @State private var hitRegions: [MathEditorHitRegion] = []

    public init(
        editorState: EditorState,
        isFocused: Bool,
        usesInternalScrollView: Bool = true,
        interactionOverlayOnly: Bool = false,
        onTapCursor: @escaping (EditorCursor) -> Void,
        onKeyboardAction: @escaping (KeyboardAction) -> Void
    ) {
        self.editorState = editorState
        self.isFocused = isFocused
        self.usesInternalScrollView = usesInternalScrollView
        self.interactionOverlayOnly = interactionOverlayOnly
        self.onTapCursor = onTapCursor
        self.onKeyboardAction = onKeyboardAction
    }

    public var body: some View {
        containerBody
        .coordinateSpace(name: "FormulaEditorSpace")
        .contentShape(Rectangle())
        .onPreferenceChange(MathEditorHitRegionPreferenceKey.self) { regions in
            hitRegions = regions
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if let cursor = resolvedCursor(at: value.location) {
                        onTapCursor(cursor)
                    }
                }
        )
#if canImport(UIKit)
        .background(
            HardwareKeyboardCaptureView(
                isFocused: isFocused,
                onAction: onKeyboardAction
            )
            .allowsHitTesting(false)
        )
#endif
        .modifier(FormulaEditorVisibilityModifier(isInteractionOverlayOnly: interactionOverlayOnly))
    }

    @ViewBuilder
    private var containerBody: some View {
        if usesInternalScrollView {
            ScrollView(.horizontal, showsIndicators: false) {
                contentBody
            }
        } else {
            contentBody
        }
    }

    private var contentBody: some View {
        HStack(spacing: 2) {
            renderNode(editorState.root, path: [])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
    }

    public static func piecewiseBraceHeight(rows: Int) -> CGFloat {
        let clamped = max(1, rows)
        // Keep this in sync with piecewise row spacing/font sizing below.
        return CGFloat(clamped) * 24 + CGFloat(clamped - 1) * 2 + 2
    }

    public static let piecewiseValueColumnMinWidth: CGFloat = 28
    public static let piecewiseConditionColumnMinWidth: CGFloat = 32
    public static let piecewiseCommaMinWidth: CGFloat = 8
    public static let piecewiseTokenSpacing: CGFloat = 4
    public static let piecewiseRowSpacing: CGFloat = 2
    public static let piecewiseBraceSpacing: CGFloat = 6

    public static let parametricBraceColumnWidth: CGFloat = 14
    public static let parametricLabelColumnWidth: CGFloat = 14
    public static let parametricEqualsColumnWidth: CGFloat = 10
    public static let parametricExpressionColumnMinWidth: CGFloat = 36
    public static let parametricRangeLeadingInset: CGFloat = 18
    public static let parametricRowSpacing: CGFloat = 2
    public static let parametricTokenSpacing: CGFloat = 4
    public static let parametricRowMinHeight: CGFloat = 24

    public static func parametricBraceHeight(xRowHeight: CGFloat, yRowHeight: CGFloat) -> CGFloat {
        xRowHeight + yRowHeight + parametricRowSpacing
    }

    public static func parametricRowHeight(lineUnits: Int) -> CGFloat {
        max(parametricRowMinHeight, CGFloat(max(1, lineUnits)) * 22)
    }

    public enum PiecewiseRowFragmentKind: Equatable {
        case valueSlot
        case commaToken
        case conditionSlot
    }

    public enum SlotHitRole: Equatable {
        case parametricX
        case parametricY
        case parametricRange
        case piecewiseValue(Int)
        case piecewiseCondition(Int)
        case fractionNumerator
        case fractionDenominator
        case superscriptBase
        case superscriptExponent
        case subscriptBase
        case subscriptField
        case rootRadicand
        case functionArgument
        case genericSlot
    }

    public static func piecewiseRowFragmentKinds() -> [PiecewiseRowFragmentKind] {
        [.valueSlot, .commaToken, .conditionSlot]
    }

    public static func piecewiseCommaLeadingX(valueContentWidth: CGFloat) -> CGFloat {
        let resolved = max(piecewiseValueColumnMinWidth, valueContentWidth)
        return resolved + piecewiseTokenSpacing
    }

    public static func preferredHeight(for state: EditorState) -> CGFloat {
        let lineUnits = max(1, lineUnits(in: state.root))
        // Keep a compact single-line editor, but allow templates to grow vertically.
        return max(44, CGFloat(lineUnits) * 22 + 12)
    }

    private static func lineUnits(in node: MathNode) -> Int {
        switch node {
        case .sequence(let nodes):
            return max(1, nodes.map(lineUnits(in:)).max() ?? 1)
        case .template(let template):
            switch template.kind {
            case .fraction:
                return 2
            case .parametricEquation2D:
                // x/y are two structured lines; range is displayed after braces.
                return 2
            case .piecewise(let rows), .cases(let rows):
                return max(2, rows)
            default:
                return 1
            }
        default:
            return 1
        }
    }

    private func renderNode(_ node: MathNode, path: [EditorPathComponent]) -> AnyView {
        switch node {
        case .sequence(let nodes):
            return AnyView(HStack(spacing: 2) {
                caretIfNeeded(path: path, offset: 0)
                ForEach(Array(nodes.enumerated()), id: \.offset) { index, child in
                    renderNode(child, path: path + [.sequenceIndex(index)])
                        .id(renderIdentity(for: child, at: path + [.sequenceIndex(index)]))
                        .contentShape(Rectangle())
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { value in
                                                let cursor = cursorForChildTap(
                                                    parentPath: path,
                                                    childIndex: index,
                                                    child: child,
                                                    locationX: value.location.x,
                                                    viewWidth: proxy.size.width
                                                )
                                                onTapCursor(cursor)
                                            }
                                    )
                            }
                        )
                    caretIfNeeded(path: path, offset: index + 1)
                }
            })
        case .character(let value), .operatorSymbol(let value), .symbol(let value):
            let boundaries = tokenBoundaryCursors(path: path)
            return AnyView(
                Text(value)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .zIndex(1)
                    .registerHitRegion(
                        id: "\(pathDescription(path))::token",
                        kind: .token,
                        cursor: boundaries.before,
                        priority: 40,
                        path: boundaries.path,
                        cursorBefore: boundaries.before,
                        cursorAfter: boundaries.after
                    )
            )
        case .placeholder:
            return AnyView(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.secondary.opacity(0.65), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.08)))
                    .frame(width: 16, height: 18)
                    .zIndex(0)
                    .contentShape(Rectangle())
                    .registerHitRegion(
                        id: "\(pathDescription(path))::placeholder",
                        kind: .placeholder,
                        cursor: cursorForPlaceholderTap(path: path),
                        priority: 100,
                        path: Array(path.dropLast())
                    )
            )
        case .template(let template):
            return renderTemplate(template, path: path)
        }
    }

    private func tokenBoundaryCursors(path: [EditorPathComponent]) -> (before: EditorCursor, after: EditorCursor, path: [EditorPathComponent]?) {
        guard !path.isEmpty else {
            let cursor = editorState.cursor
            return (before: cursor, after: cursor, path: cursor.path)
        }
        let parent = Array(path.dropLast())
        if case .sequenceIndex(let index) = path.last {
            return (
                before: EditorCursor(path: parent, offset: index),
                after: EditorCursor(path: parent, offset: index + 1),
                path: parent
            )
        }
        let fallback = EditorCursor(path: parent, offset: 0)
        return (before: fallback, after: fallback, path: parent)
    }

    private func cursorForPlaceholderTap(path: [EditorPathComponent]) -> EditorCursor {
        if path.count >= 2,
           case .sequenceIndex(let nodeIndex) = path[path.count - 1],
           case .templateField = path[path.count - 2] {
            return EditorCursor(path: Array(path.dropLast(1)), offset: nodeIndex)
        }
        return EditorCursor(path: [], offset: sequenceCount(at: [], in: editorState.root))
    }

    private func renderTemplate(_ template: TemplateNode, path: [EditorPathComponent]) -> AnyView {
        switch template.kind {
        case .superscript:
            return AnyView(
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                renderNode(template.field(.base) ?? .sequence([.placeholder]), path: path + [.templateField(.base)])
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onTapCursor(Self.slotEntryCursor(path: path, kind: .superscript, field: .base))
                    })
                VStack(alignment: .leading, spacing: 1) {
                    renderNode(template.field(.exponent) ?? .sequence([.placeholder]), path: path + [.templateField(.exponent)])
                        .scaleEffect(0.78, anchor: .leading)
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded {
                            onTapCursor(Self.slotEntryCursor(path: path, kind: .superscript, field: .exponent))
                        })
                }
                .offset(y: -8)
                }
                .registerHitRegion(
                    id: "\(pathDescription(path))::templateBody",
                    kind: .templateBody,
                    cursor: Self.templateEntryCursor(path: path, kind: template.kind),
                    priority: 10
                )
            )
        case .fraction:
            return AnyView(
                VStack(spacing: 2) {
                renderNode(template.field(.numerator) ?? .sequence([.placeholder]), path: path + [.templateField(.numerator)])
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onTapCursor(Self.slotEntryCursor(path: path, kind: .fraction, field: .numerator))
                    })
                Rectangle()
                    .fill(Color.primary.opacity(0.65))
                    .frame(height: 1)
                renderNode(template.field(.denominator) ?? .sequence([.placeholder]), path: path + [.templateField(.denominator)])
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onTapCursor(Self.slotEntryCursor(path: path, kind: .fraction, field: .denominator))
                    })
                }
                .padding(.horizontal, 2)
                .registerHitRegion(
                    id: "\(pathDescription(path))::templateBody",
                    kind: .templateBody,
                    cursor: Self.templateEntryCursor(path: path, kind: template.kind),
                    priority: 10
                )
            )
        case .subscriptTemplate:
            return AnyView(HStack(alignment: .firstTextBaseline, spacing: 1) {
                renderNode(template.field(.base) ?? .sequence([.placeholder]), path: path + [.templateField(.base)])
                VStack(alignment: .leading, spacing: 1) {
                    renderNode(template.field(.subscriptField) ?? .sequence([.placeholder]), path: path + [.templateField(.subscriptField)])
                        .scaleEffect(0.78, anchor: .leading)
                }
                .offset(y: 7)
            })
        case .sqrt:
            return AnyView(
                HStack(spacing: 2) {
                Text("√")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                renderNode(template.field(.radicand) ?? .sequence([.placeholder]), path: path + [.templateField(.radicand)])
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onTapCursor(Self.slotEntryCursor(path: path, kind: .sqrt, field: .radicand))
                    })
                }
                .registerHitRegion(
                    id: "\(pathDescription(path))::templateBody",
                    kind: .templateBody,
                    cursor: Self.templateEntryCursor(path: path, kind: template.kind),
                    priority: 10
                )
            )
        case .parametricEquation2D:
            let rangeNode = template.field(.parametricRange)
            let hasRangeContent = rangeNode.map { !$0.isEmptyForEditing } ?? false
            let isEditingRange = editorState.cursor.path == path + [.templateField(.parametricRange)]
            let hasRange = hasRangeContent || isEditingRange
            let xNode = template.field(.parametricExpression(0)) ?? .sequence([.placeholder])
            let yNode = template.field(.parametricExpression(1)) ?? .sequence([.placeholder])
            let xRowHeight = Self.parametricRowHeight(lineUnits: Self.lineUnits(in: xNode))
            let yRowHeight = Self.parametricRowHeight(lineUnits: Self.lineUnits(in: yNode))
            let braceHeight = Self.parametricBraceHeight(xRowHeight: xRowHeight, yRowHeight: yRowHeight)
            return AnyView(
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 4) {
                        HStack(alignment: .top, spacing: 4) {
                            ScalableLeftBraceShape()
                                .stroke(Color.primary.opacity(0.78), lineWidth: 1.35)
                                .frame(width: 12, height: braceHeight)
                                .padding(.top, 1)
                                .frame(width: Self.parametricBraceColumnWidth, alignment: .leading)
                            VStack(alignment: .leading, spacing: Self.parametricRowSpacing) {
                                HStack(alignment: .firstTextBaseline, spacing: Self.parametricTokenSpacing) {
                                    Text("x")
                                        .fixedSize(horizontal: true, vertical: false)
                                        .frame(width: Self.parametricLabelColumnWidth, alignment: .trailing)
                                    Text("=")
                                        .fixedSize(horizontal: true, vertical: false)
                                        .frame(width: Self.parametricEqualsColumnWidth, alignment: .center)
                                    renderNode(
                                        xNode,
                                        path: path + [.templateField(.parametricExpression(0))]
                                    )
                                    .frame(minWidth: Self.parametricExpressionColumnMinWidth, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .highPriorityGesture(TapGesture().onEnded {
                                        onTapCursor(Self.slotEntryCursor(path: path, kind: .parametricEquation2D, field: .parametricExpression(0)))
                                    })
                                }
                                .frame(minHeight: xRowHeight, alignment: .leading)
                                HStack(alignment: .firstTextBaseline, spacing: Self.parametricTokenSpacing) {
                                    Text("y")
                                        .fixedSize(horizontal: true, vertical: false)
                                        .frame(width: Self.parametricLabelColumnWidth, alignment: .trailing)
                                    Text("=")
                                        .fixedSize(horizontal: true, vertical: false)
                                        .frame(width: Self.parametricEqualsColumnWidth, alignment: .center)
                                    renderNode(
                                        yNode,
                                        path: path + [.templateField(.parametricExpression(1))]
                                    )
                                    .frame(minWidth: Self.parametricExpressionColumnMinWidth, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .highPriorityGesture(TapGesture().onEnded {
                                        onTapCursor(Self.slotEntryCursor(path: path, kind: .parametricEquation2D, field: .parametricExpression(1)))
                                    })
                                }
                                .frame(minHeight: yRowHeight, alignment: .leading)
                            }
                        }
                        .font(.system(size: 20, weight: .medium, design: .serif))
                    }

                    if hasRange {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Color.clear
                                .frame(width: Self.parametricRangeLeadingInset, height: 1)
                            Text(",")
                                .fixedSize(horizontal: true, vertical: true)
                            renderNode(
                                template.field(.parametricRange) ?? .sequence([.placeholder]),
                                path: path + [.templateField(.parametricRange)]
                            )
                            .frame(minWidth: Self.parametricExpressionColumnMinWidth, alignment: .leading)
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                onTapCursor(Self.slotEntryCursor(path: path, kind: .parametricEquation2D, field: .parametricRange))
                            })
                        }
                        .font(.system(size: 20, weight: .medium, design: .serif))
                    }
                }
                .registerHitRegion(
                    id: "\(pathDescription(path))::templateBody",
                    kind: .templateBody,
                    cursor: Self.templateEntryCursor(path: path, kind: template.kind),
                    priority: 10
                )
            )
        case .piecewise(let rows):
            return AnyView(renderPiecewiseTemplate(template, rows: rows, path: path))
        case .cases(let rows):
            return AnyView(renderCasesTemplate(template, rows: rows, path: path))
        case .absoluteValue:
            return AnyView(HStack(spacing: 1) {
                Text("|")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                renderNode(template.field(.content) ?? .sequence([.placeholder]), path: path + [.templateField(.content)])
                Text("|")
                    .font(.system(size: 24, weight: .regular, design: .serif))
            })
        case .sin, .cos, .tan, .ln, .exp, .log:
            let name: String
            switch template.kind {
            case .sin: name = "sin"
            case .cos: name = "cos"
            case .tan: name = "tan"
            case .ln: name = "ln"
            case .exp: name = "exp"
            case .log: name = "log"
            default: name = ""
            }
            return AnyView(HStack(spacing: 1) {
                Text(name)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                Text("(")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                renderNode(template.field(.argument) ?? .sequence([.placeholder]), path: path + [.templateField(.argument)])
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onTapCursor(Self.slotEntryCursor(path: path, kind: template.kind, field: .argument))
                    })
                Text(")")
                    .font(.system(size: 22, weight: .medium, design: .serif))
            }
            .contentShape(Rectangle())
            .registerHitRegion(
                id: "\(pathDescription(path))::templateBody",
                kind: .templateBody,
                cursor: Self.templateEntryCursor(path: path, kind: template.kind),
                priority: 10
            ))
        default:
            return AnyView(
                Text("□")
                    .font(.system(size: 20, weight: .regular, design: .serif))
            )
        }
    }

    @ViewBuilder
    private func caretIfNeeded(path: [EditorPathComponent], offset: Int) -> some View {
        if isFocused, editorState.cursor.path == path, editorState.cursor.offset == offset {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 1.5, height: 24)
                .padding(.horizontal, 1)
        }
    }

    private func sequenceCount(at path: [EditorPathComponent], in root: MathNode) -> Int {
        MathEditorTree.sequence(at: path, in: root)?.count ?? 0
    }

    private func cursorForChildTap(
        parentPath: [EditorPathComponent],
        childIndex: Int,
        child: MathNode,
        locationX: CGFloat,
        viewWidth: CGFloat
    ) -> EditorCursor {
        if case .template(let template) = child {
            return Self.templateEntryCursor(path: parentPath + [.sequenceIndex(childIndex)], kind: template.kind)
        }

        let boundary = Self.sequenceBoundaryOffsetForTokenTap(
            locationX: locationX,
            viewWidth: viewWidth,
            tokenIndex: childIndex
        )
        return EditorCursor(path: parentPath, offset: boundary)
    }

    public static func sequenceBoundaryOffsetForTokenTap(
        locationX: CGFloat,
        viewWidth: CGFloat,
        tokenIndex: Int
    ) -> Int {
        guard viewWidth > 0 else { return tokenIndex }
        return locationX < viewWidth * 0.5 ? tokenIndex : tokenIndex + 1
    }

    public static func templateEntryCursor(path: [EditorPathComponent], kind: TemplateKind) -> EditorCursor {
        let definition = TemplateDefinitionRegistry.definition(for: kind)
        return EditorCursor(path: path + [.templateField(definition.initialField)], offset: 0)
    }

    public static func slotEntryCursor(
        path: [EditorPathComponent],
        kind: TemplateKind,
        field: FieldID
    ) -> EditorCursor {
        let definition = TemplateDefinitionRegistry.definition(for: kind)
        let resolvedField = definition.fields.contains(field) ? field : definition.initialField
        return EditorCursor(path: path + [.templateField(resolvedField)], offset: 0)
    }

    public static func slotRoleToField(_ role: SlotHitRole) -> FieldID {
        switch role {
        case .parametricX:
            return .parametricExpression(0)
        case .parametricY:
            return .parametricExpression(1)
        case .parametricRange:
            return .parametricRange
        case .piecewiseValue(let row):
            return .rowExpression(row)
        case .piecewiseCondition(let row):
            return .rowCondition(row)
        case .fractionNumerator:
            return .numerator
        case .fractionDenominator:
            return .denominator
        case .superscriptBase:
            return .base
        case .superscriptExponent:
            return .exponent
        case .subscriptBase:
            return .base
        case .subscriptField:
            return .subscriptField
        case .rootRadicand:
            return .radicand
        case .functionArgument:
            return .argument
        case .genericSlot:
            return .content
        }
    }

    private func renderIdentity(for node: MathNode, at path: [EditorPathComponent]) -> String {
        "\(path.map { String(describing: $0) }.joined(separator: "/"))|\(node.debugTree)"
    }

    private func pathDescription(_ path: [EditorPathComponent]) -> String {
        path.map { String(describing: $0) }.joined(separator: "/")
    }

    private func resolvedCursor(at point: CGPoint) -> EditorCursor? {
        if let region = Self.resolveHitRegion(at: point, in: hitRegions) {
            if case .token = region.kind {
                return Self.nearestTokenBoundaryCursor(point: point, tokenRegion: region) ?? region.cursor
            }
            return region.cursor
        }
        return Self.resolveFallbackCursor(at: point, regions: hitRegions, root: editorState.root)
    }

    public static func resolveHitRegion(at point: CGPoint, in regions: [MathEditorHitRegion]) -> MathEditorHitRegion? {
        let candidates = regions.filter { $0.rect.contains(point) }
        guard !candidates.isEmpty else { return nil }
        return candidates.sorted {
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            let area0 = $0.rect.width * $0.rect.height
            let area1 = $1.rect.width * $1.rect.height
            return area0 < area1
        }.first
    }

    public static func nearestTokenBoundaryCursor(point: CGPoint, tokenRegion: MathEditorHitRegion) -> EditorCursor? {
        guard case .token = tokenRegion.kind else { return tokenRegion.cursor }
        let before = tokenRegion.cursorBefore ?? tokenRegion.cursor
        let after = tokenRegion.cursorAfter ?? tokenRegion.cursor
        guard let before, let after else { return nil }
        guard tokenRegion.rect.width > 0 else { return before }
        return point.x < tokenRegion.rect.midX ? before : after
    }

    public static func resolveFallbackCursor(at point: CGPoint, regions: [MathEditorHitRegion], root: MathNode) -> EditorCursor? {
        let fallbackEligible = regions.filter {
            switch $0.kind {
            case .editableSlot, .placeholder, .token, .templateBody:
                return true
            case .formulaBody:
                return false
            }
        }
        guard !fallbackEligible.isEmpty else { return nil }

        let sameRow = fallbackEligible.filter { $0.rect.minY <= point.y && point.y <= $0.rect.maxY }
        let rowCandidates = sameRow.isEmpty ? fallbackEligible : sameRow
        guard let nearest = rowCandidates.min(by: { lhs, rhs in
            let d0 = horizontalDistance(from: point.x, to: lhs.rect)
            let d1 = horizontalDistance(from: point.x, to: rhs.rect)
            if d0 != d1 { return d0 < d1 }
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            let a0 = lhs.rect.width * lhs.rect.height
            let a1 = rhs.rect.width * rhs.rect.height
            return a0 < a1
        }) else {
            return nil
        }

        if case .token = nearest.kind {
            if let cursor = Self.nearestTokenBoundaryCursor(point: point, tokenRegion: nearest) {
                return cursor
            }
            return nearest.cursor
        }

        if case .templateBody = nearest.kind {
            return nearest.cursor
        }

        if let path = nearest.path {
            if point.x >= nearest.rect.maxX {
                return EditorCursor(path: path, offset: MathEditorTree.sequence(at: path, in: root)?.count ?? 0)
            }
            if point.x <= nearest.rect.minX {
                return EditorCursor(path: path, offset: 0)
            }
        }
        return nearest.cursor
    }

    private static func horizontalDistance(from x: CGFloat, to rect: CGRect) -> CGFloat {
        if x < rect.minX { return rect.minX - x }
        if x > rect.maxX { return x - rect.maxX }
        return 0
    }

    @ViewBuilder
    private func renderPiecewiseTemplate(_ template: TemplateNode, rows: Int, path: [EditorPathComponent]) -> some View {
        HStack(alignment: .top, spacing: Self.piecewiseBraceSpacing) {
            ScalableLeftBraceShape()
                .stroke(Color.primary.opacity(0.78), lineWidth: 1.35)
                .frame(width: 12, height: Self.piecewiseBraceHeight(rows: rows))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: Self.piecewiseRowSpacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(alignment: .firstTextBaseline, spacing: Self.piecewiseTokenSpacing) {
                        renderNode(
                            template.field(.rowExpression(row)) ?? .sequence([.placeholder]),
                            path: path + [.templateField(.rowExpression(row))]
                        )
                        .frame(minWidth: Self.piecewiseValueColumnMinWidth, alignment: .leading)
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded {
                            onTapCursor(Self.slotEntryCursor(path: path, kind: .piecewise(rows: rows), field: .rowExpression(row)))
                        })

                        Text(",")
                            .fixedSize(horizontal: true, vertical: true)
                            .frame(minWidth: Self.piecewiseCommaMinWidth, alignment: .center)

                        renderNode(
                            template.field(.rowCondition(row)) ?? .sequence([.placeholder]),
                            path: path + [.templateField(.rowCondition(row))]
                        )
                        .frame(minWidth: Self.piecewiseConditionColumnMinWidth, alignment: .leading)
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded {
                            onTapCursor(Self.slotEntryCursor(path: path, kind: .piecewise(rows: rows), field: .rowCondition(row)))
                        })
                    }
                    .frame(minHeight: 24, alignment: .leading)
                }
            }
            .font(.system(size: 20, weight: .medium, design: .serif))
        }
    }

    @ViewBuilder
    private func renderCasesTemplate(_ template: TemplateNode, rows: Int, path: [EditorPathComponent]) -> some View {
        HStack(alignment: .top, spacing: 6) {
            ScalableLeftBraceShape()
                .stroke(Color.primary.opacity(0.78), lineWidth: 1.35)
                .frame(width: 12, height: Self.piecewiseBraceHeight(rows: rows))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 2) {
                        renderNode(template.field(.rowExpression(row)) ?? .sequence([.placeholder]), path: path + [.templateField(.rowExpression(row))])
                    }
                    .frame(minHeight: 24, alignment: .leading)
                }
            }
            .font(.system(size: 20, weight: .medium, design: .serif))
        }
    }
}

private struct FormulaEditorVisibilityModifier: ViewModifier {
    let isInteractionOverlayOnly: Bool

    func body(content: Content) -> some View {
        if isInteractionOverlayOnly {
            content.hidden()
        } else {
            content
        }
    }
}

private extension View {
    public func registerHitRegion(
        id: String,
        kind: MathEditorHitRegion.Kind,
        cursor: EditorCursor?,
        priority: Int,
        path: [EditorPathComponent]? = nil,
        cursorBefore: EditorCursor? = nil,
        cursorAfter: EditorCursor? = nil
    ) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MathEditorHitRegionPreferenceKey.self,
                    value: [
                        MathEditorHitRegion(
                            id: id,
                            kind: kind,
                            rect: proxy.frame(in: .named("FormulaEditorSpace")),
                            cursor: cursor,
                            path: path,
                            cursorBefore: cursorBefore,
                            cursorAfter: cursorAfter,
                            priority: priority
                        )
                    ]
                )
            }
        )
    }
}

private struct ScalableLeftBraceShape: Shape {
    public func path(in rect: CGRect) -> Path {
        let w = max(1, rect.width)
        let h = max(1, rect.height)
        let midY = h * 0.5
        let insetX = w * 0.12
        let outerX = w * 0.92
        let shoulder = h * 0.18
        let neck = h * 0.08

        var path = Path()
        path.move(to: CGPoint(x: outerX, y: 0))
        path.addCurve(
            to: CGPoint(x: insetX, y: shoulder),
            control1: CGPoint(x: w * 0.38, y: 0),
            control2: CGPoint(x: insetX, y: shoulder * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: midY - neck),
            control1: CGPoint(x: insetX, y: shoulder + h * 0.08),
            control2: CGPoint(x: w * 0.58, y: midY - neck * 1.3)
        )
        path.addCurve(
            to: CGPoint(x: insetX, y: h - shoulder),
            control1: CGPoint(x: w * 0.58, y: midY + neck * 1.3),
            control2: CGPoint(x: insetX, y: h - shoulder - h * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: outerX, y: h),
            control1: CGPoint(x: insetX, y: h - shoulder * 0.55),
            control2: CGPoint(x: w * 0.38, y: h)
        )
        return path
    }
}
