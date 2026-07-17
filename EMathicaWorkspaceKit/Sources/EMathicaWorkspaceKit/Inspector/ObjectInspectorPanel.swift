import EMathicaThemeKit
import EMathicaDocumentKit
import EMathicaMathCore
import SwiftUI

public struct ObjectInspectorPanel: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var state: WorkspaceState
    @State private var selectedTab: InspectorTab = .object
    public var showsHeader: Bool = true
    public var onClose: (() -> Void)?

    private var selectedObject: MathObject? {
        guard let id = state.selectedObjectID else { return nil }
        return state.document.objects.first(where: { $0.id == id })
    }

    public var body: some View {
        LiquidGlassPanel(theme: .sidePanel) {
            VStack(spacing: 12) {
                if showsHeader {
                    header
                }

                content
            }
        }
        .onAppear {
            selectedTab = selectedObject == nil ? .canvas : .object
        }
        .onChange(of: selectedObject?.id) { _, newValue in
            if newValue == nil, selectedTab == .object {
                selectedTab = .canvas
            } else if newValue != nil {
                selectedTab = .object
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Inspector")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Spacer(minLength: 0)
            Button {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: Circle())
            .accessibilityLabel("收起 Inspector")
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Inspector", selection: $selectedTab) {
                        if selectedObject != nil {
                            Text("对象").tag(InspectorTab.object)
                        }
                        Text("画布").tag(InspectorTab.canvas)
                        Text("计算器").tag(InspectorTab.calculator)
                    }
                    .pickerStyle(.segmented)

                    switch selectedTab {
                    case .object:
                        if let object = selectedObject {
                            objectContent(object)
                        } else {
                            canvasSection
                            calculatorSection
                        }
                    case .canvas:
                        canvasSection
                    case .calculator:
                        calculatorSection
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func objectContent(_ object: MathObject) -> some View {
                        InspectorSection(title: "对象") {
                            InspectorLine(label: "名称", value: object.name)
                            InspectorLine(label: "类型", value: object.type.rawValue)
                            if let displayLine = InspectorFormulaSourceBuilder.objectLines(for: object).first {
                                InspectorFormulaLine(
                                    label: displayLine.label,
                                    source: displayLine.source,
                                    configuration: state.effectiveReadOnlyFormulaDisplayConfiguration
                                )
                            }
                            InspectorLine(label: "可见", value: object.isVisible ? "是" : "否")
                            InspectorLine(label: "颜色", value: colorLabel(for: object.style.colorToken))
                        }

                        geometrySection(object)

                        styleSection(object)

                        if object.type == .parameter {
                            parameterSection(object)
                        }

                        if let analysis = object.expression.algebraAnalysis {
                            algebraSection(analysis)
                            rewriteSection(analysis)
                            diagnosticsSection(analysis)
                        }
    }

    @ViewBuilder
    private func geometrySection(_ object: MathObject) -> some View {
        let rows = geometryRows(for: object)
        if !rows.isEmpty {
            InspectorSection(title: "几何属性") {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    InspectorLine(label: row.label, value: row.value)
                }
            }
        }
    }

    private func geometryRows(for object: MathObject) -> [GeometryInspectorPropertyRow] {
        if let kind = object.geometryDefinition?.kind,
           kind == .point3D || kind == .segment3D || kind == .line3D || kind == .plane3D {
            return SpaceGeometryInspectorPropertyPresenter.rows(for: object)
        }
        return GeometryInspectorPropertyPresenter.rows(
            for: object,
            objects: state.document.objects,
            geometryResolver: state.geometryPresentationResolver
        )
    }

    private func styleSection(_ object: MathObject) -> some View {
        InspectorSection(title: "样式") {
            VStack(alignment: .leading, spacing: 12) {
                Text("颜色")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 34), spacing: 8)], spacing: 8) {
                    ForEach(ColorToken.allCases, id: \.self) { token in
                        Button {
                            state.dispatch(.updateObjectStyle(
                                id: object.id,
                                colorToken: token.rawValue,
                                opacity: nil,
                                fillOpacity: nil,
                                lineWidth: nil,
                                pointSize: nil,
                                lineStyle: nil
                            ))
                        } label: {
                            Circle()
                                .fill(token.resolvedColor())
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle()
                                        .stroke(Color.primary.opacity(token.rawValue == object.style.colorToken ? 0.70 : 0.10), lineWidth: token.rawValue == object.style.colorToken ? 2.5 : 1)
                                }
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("颜色 \(token.rawValue)")
                    }
                }

                ColorPicker(
                    "调色盘取色",
                    selection: customColorBinding(for: object.id),
                    supportsOpacity: false
                )
                .font(.system(size: 12, weight: .medium))

                opacityRow(
                    title: "线条透明度",
                    value: object.style.opacity,
                    onChange: { value in
                        state.dispatch(.updateObjectStyle(id: object.id, colorToken: nil, opacity: value, fillOpacity: nil, lineWidth: nil, pointSize: nil, lineStyle: nil))
                    }
                )

                opacityRow(
                    title: "填充透明度",
                    value: object.style.fillOpacity,
                    onChange: { value in
                        state.dispatch(.updateObjectStyle(id: object.id, colorToken: nil, opacity: nil, fillOpacity: value, lineWidth: nil, pointSize: nil, lineStyle: nil))
                    }
                )
            }
        }
    }

    private func opacityRow(title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer(minLength: 0)
                Text("\(Int((value * 100).rounded()))%")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: .medium))

            Slider(
                value: Binding(
                    get: { value },
                    set: { onChange($0) }
                ),
                in: 0...1
            )
        }
    }

    private func colorLabel(for styleColor: String) -> String {
        if let hex = ColorToken.customHex(from: styleColor) {
            return hex
        }
        return styleColor
    }

    private func customColorBinding(for objectID: UUID) -> Binding<Color> {
        Binding(
            get: {
                let styleColor = state.document.objects.first(where: { $0.id == objectID })?.style.colorToken ?? ColorToken.blue.rawValue
                return ColorToken.resolvedColor(from: styleColor)
            },
            set: { color in
                guard let hex = color.rgbHexString() else { return }
                let normalizedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                state.dispatch(.updateObjectStyle(
                    id: objectID,
                    colorToken: "hex:\(normalizedHex)",
                    opacity: nil,
                    fillOpacity: nil,
                    lineWidth: nil,
                    pointSize: nil,
                    lineStyle: nil
                ))
            }
        )
    }

    private func parameterSection(_ object: MathObject) -> some View {
        let currentSettings = object.sliderSettings ?? SliderSettings.default
        let range = min(currentSettings.min, currentSettings.max)...max(currentSettings.min, currentSettings.max)
        return InspectorSection(title: "参数") {
            let value = Binding<Double>(
                get: { object.parameterValue ?? 1 },
                set: { state.updateParameter(id: object.id, value: $0) }
            )
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(object.name)
                    Spacer()
                    Text(format(value.wrappedValue))
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: value,
                    in: range
                )

                HStack(spacing: 8) {
                    Text("最小值")
                    TextField(
                        "",
                        value: Binding(
                            get: { currentSettings.min },
                            set: { newMin in
                                var next = currentSettings
                                next.min = newMin
                                state.updateSliderSettings(id: object.id, settings: next)
                            }
                        ),
                        format: .number.precision(.fractionLength(0...6))
                    )
                    .multilineTextAlignment(.trailing)
                }

                HStack(spacing: 8) {
                    Text("最大值")
                    TextField(
                        "",
                        value: Binding(
                            get: { currentSettings.max },
                            set: { newMax in
                                var next = currentSettings
                                next.max = newMax
                                state.updateSliderSettings(id: object.id, settings: next)
                            }
                        ),
                        format: .number.precision(.fractionLength(0...6))
                    )
                    .multilineTextAlignment(.trailing)
                }

                HStack(spacing: 8) {
                    Text("步长")
                    TextField(
                        "",
                        value: Binding(
                            get: { currentSettings.step },
                            set: { newStep in
                                var next = currentSettings
                                next.step = newStep
                                state.updateSliderSettings(id: object.id, settings: next)
                            }
                        ),
                        format: .number.precision(.fractionLength(0...6))
                    )
                    .multilineTextAlignment(.trailing)
                }

                Stepper(
                    "精度：\(currentSettings.precision)",
                    value: Binding(
                        get: { currentSettings.precision },
                        set: { newPrecision in
                            var next = currentSettings
                            next.precision = newPrecision
                            state.updateSliderSettings(id: object.id, settings: next)
                        }
                    ),
                    in: 0...8
                )

                HStack {
                    Text("速度")
                    Slider(
                        value: Binding(
                            get: { currentSettings.speed },
                            set: { newSpeed in
                                var next = currentSettings
                                next.speed = newSpeed
                                state.updateSliderSettings(id: object.id, settings: next)
                            }
                        ),
                        in: 0.1...10
                    )
                }

                Picker(
                    "方向",
                    selection: Binding(
                        get: { currentSettings.playbackMode },
                        set: { newMode in
                            var next = currentSettings
                            next.playbackMode = newMode
                            state.updateSliderSettings(id: object.id, settings: next)
                        }
                    )
                ) {
                    Text("递增").tag(SliderPlaybackMode.increasing)
                    Text("递减").tag(SliderPlaybackMode.decreasing)
                    Text("往复").tag(SliderPlaybackMode.pingPong)
                }
                .pickerStyle(.segmented)
            }
            .font(.system(size: 13, weight: .medium))
        }
    }

    private func algebraSection(_ analysis: AlgebraAnalysisResult) -> some View {
        InspectorSection(title: "CAS") {
            ForEach(Array(InspectorFormulaSourceBuilder.algebraLines(for: analysis).enumerated()), id: \.offset) { _, line in
                InspectorFormulaLine(
                    label: line.label,
                    source: line.source,
                    configuration: state.effectiveReadOnlyFormulaDisplayConfiguration
                )
            }
            InspectorLine(label: "recognizedShape", value: analysis.recognizedShape?.displayName ?? "未识别")
            InspectorLine(label: "graphKind", value: analysis.classification.kind.rawValue)
            InspectorLine(label: "plotStrategy", value: analysis.plotStrategy?.displayName ?? "默认")
            InspectorLine(label: "unresolvedSymbols", value: analysis.unresolvedSymbols.isEmpty ? "无" : analysis.unresolvedSymbols.joined(separator: ", "))
        }
    }

    @ViewBuilder
    private func rewriteSection(_ analysis: AlgebraAnalysisResult) -> some View {
        if let rewriteInfo = analysis.rewriteInfo {
            InspectorSection(title: "参数化重写") {
                InspectorLine(label: "rewriteInfo", value: rewriteInfo.summary)
                ForEach(Array(InspectorFormulaSourceBuilder.rewriteLines(for: analysis).enumerated()), id: \.offset) { _, line in
                    InspectorFormulaLine(
                        label: line.label,
                        source: line.source,
                        configuration: state.effectiveReadOnlyFormulaDisplayConfiguration
                    )
                }
                if let restrictions = analysis.restrictions, !restrictions.isEmpty {
                    InspectorLine(label: "restrictions", value: restrictions.joined(separator: ", "))
                }
            }
        }
    }

    private func diagnosticsSection(_ analysis: AlgebraAnalysisResult) -> some View {
        InspectorSection(title: "诊断") {
            if analysis.diagnostics.isEmpty {
                InspectorLine(label: "diagnostics", value: "无")
            } else {
                ForEach(Array(analysis.diagnostics.enumerated()), id: \.offset) { _, diagnostic in
                    InspectorLine(label: diagnostic.severity.rawValue, value: diagnostic.message)
                }
            }
        }
    }

    private var canvasSection: some View {
        InspectorSection(title: "画布设置") {
            Toggle("网格显示", isOn: Binding(
                get: { state.document.canvasState.showGrid },
                set: { state.updateCanvas(showGrid: $0) }
            ))
            Toggle("坐标轴显示", isOn: Binding(
                get: { state.document.canvasState.showAxis },
                set: { state.updateCanvas(showAxis: $0) }
            ))
            InspectorLine(label: "网格密度", value: format(state.document.canvasState.scale))
            InspectorLine(label: "坐标轴样式", value: "标准")
            InspectorLine(label: "背景风格", value: "液态玻璃画布")
            Button("重置视图") {
                state.dispatch(.setCanvasViewport(.default))
            }
            .buttonStyle(.bordered)
        }
    }

    private var calculatorSection: some View {
        InspectorSection(title: "平面计算器设置") {
            InspectorLine(label: "工具栏顺序", value: "选择 / 几何 / 函数")
            InspectorLine(label: "默认工具", value: "选择")
            InspectorLine(label: "输入模式", value: "expression")
            InspectorLine(label: "角度单位", value: "弧度")
            InspectorLine(label: "采样精度", value: "自动")
            InspectorLine(label: "参数滑条默认范围", value: "-10...10")
        }
    }

    private func format(_ value: Double) -> String {
        let rounded = (value * 1000).rounded() / 1000
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}

private enum InspectorTab: Hashable {
    case object
    case canvas
    case calculator
}

private struct InspectorSection<Content: View>: View {
    public var title: String
    @ViewBuilder var content: Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct InspectorLine: View {
    public var label: String
    public var value: String

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(value)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum InspectorFormulaLayout {
    static let maximumHeight: CGFloat = 152
}

private struct InspectorFormulaLine: View {
    let label: String
    let source: WorkspaceReadOnlyFormulaSource
    let configuration: FormulaRenderingConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            WorkspaceReadOnlyFormulaText(
                surface: .inspector,
                rawValue: source.rawValue,
                fallbackText: source.fallbackText,
                tint: .primary,
                fontSize: source.fontSize,
                minHeight: source.minHeight,
                maxHeight: InspectorFormulaLayout.maximumHeight,
                allowsMultiline: source.allowsMultiline,
                configuration: configuration
            )
        }
    }
}

private extension RecognizedShapeKind {
    public var displayName: String {
        switch self {
        case .circle:
            return "圆"
        case .ellipse:
            return "椭圆"
        case .hyperbola:
            return "双曲线"
        case .parabola:
            return "抛物线"
        case .superellipse:
            return "超椭圆"
        }
    }
}

private extension PlotStrategyKind {
    public var displayName: String {
        switch self {
        case .explicitY: return "y=f(x)"
        case .explicitX: return "x=f(y)"
        case .horizontalLine: return "水平线"
        case .verticalLine: return "竖直线"
        case .conicParametric: return "圆锥参数绘制"
        case .parametric: return "参数绘制"
        case .implicit: return "隐式"
        case .unsupported: return "不支持"
        }
    }
}
