import EMathicaThemeKit
import EMathicaMathCore
import SwiftUI

public struct AlgebraObjectPanelView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var state: WorkspaceState
    public var onRequestDeleteObjects: (Set<UUID>) -> Void = { _ in }
    public var onToggleFullscreen: (() -> Void)?
    public var isFullscreen: Bool = false
    @State private var sliderSettingsSheetObjectID: UUID?

    public var body: some View {
        LiquidGlassPanel(theme: objectPanelTheme) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if panelSections.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: AlgebraObjectPanelLayoutMetrics.sectionSpacing) {
                            ForEach(panelSections) { section in
                                objectSection(section)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .sheet(item: sliderSettingsSheetBinding, content: sliderSettingsSheetContent(for:))
    }

    private var sliderSettingsSheetBinding: Binding<SliderSettingsSheetItem?> {
        Binding(
            get: {
                guard let id = sliderSettingsSheetObjectID else { return nil }
                return SliderSettingsSheetItem(id: id)
            },
            set: { newValue in
                sliderSettingsSheetObjectID = newValue?.id
            }
        )
    }

    @ViewBuilder
    private func sliderSettingsSheetContent(for item: SliderSettingsSheetItem) -> some View {
        if let object = state.document.objects.first(where: { $0.id == item.id && $0.type == .parameter }) {
            SliderSettingsSheet(
                object: object,
                onCancel: { sliderSettingsSheetObjectID = nil },
                onSave: { settings, value in
                    state.updateSliderSettings(id: object.id, settings: settings, value: value)
                    sliderSettingsSheetObjectID = nil
                }
            )
        } else {
            EmptyView()
        }
    }

    private var panelSections: [AlgebraObjectPanelSection] {
        AlgebraObjectPanelSection.makeSections(from: state.document.objects)
    }

    @ViewBuilder
    private func objectSection(_ section: AlgebraObjectPanelSection) -> some View {
        VStack(alignment: .leading, spacing: AlgebraObjectPanelLayoutMetrics.sectionHeaderToContentSpacing) {
            HStack(spacing: 8) {
                Image(systemName: section.systemImageName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(section.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText.opacity(0.92))

                Text("\(section.objects.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
                    )

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: AlgebraObjectPanelLayoutMetrics.sectionHeaderHeight, alignment: .leading)

            VStack(spacing: AlgebraObjectPanelLayoutMetrics.rowSpacing) {
                ForEach(section.objects) { object in
                    objectRow(for: object)
                }
            }
        }
    }

    @ViewBuilder
    private func objectRow(for object: MathObject) -> some View {
        if object.type == .parameter {
            ParameterObjectRowView(
                object: object,
                isSelected: state.selectedObjectID == object.id,
                isPlaying: state.isSliderPlaying(id: object.id),
                onSelect: { state.dispatch(.selectObject(id: object.id)) },
                onTogglePlayback: { state.toggleSliderPlayback(id: object.id) },
                onValueChange: { state.updateParameter(id: object.id, value: $0) },
                onUpdateSettings: { state.updateSliderSettings(id: object.id, settings: $0) },
                onOpenCustomSettings: {
                    state.dispatch(.selectObject(id: object.id))
                    sliderSettingsSheetObjectID = object.id
                },
                onDelete: { onRequestDeleteObjects([object.id]) },
                onOpenSettings: {
                    state.dispatch(.selectObject(id: object.id))
                    state.dispatch(.setInspectorVisible(true))
                }
            )
        } else {
            WorkspaceObjectRowView(
                object: object,
                allObjects: state.document.objects,
                isSelected: state.selectedObjectID == object.id,
                onTap: {
                    state.dispatch(.selectObject(id: object.id))
                },
                onToggleVisibility: {
                    state.dispatch(.toggleObjectVisibility(id: object.id))
                },
                onDelete: {
                    onRequestDeleteObjects([object.id])
                },
                onEditExpression: {
                    state.beginEditingObjectExpression(object.id, openKeyboard: true)
                },
                onOpenSettings: {
                    state.dispatch(.selectObject(id: object.id))
                    state.dispatch(.setInspectorVisible(true))
                },
                onConvertToStatic: {
                    state.dispatch(.selectObject(id: object.id))
                    state.dispatch(.convertObjectToStatic(id: object.id))
                },
                onUpdateStyle: { updatedStyle in
                    state.dispatch(.selectObject(id: object.id))
                    state.updateObjectStyle(id: object.id, style: updatedStyle)
                },
                onDerivative: object.type == .function ? {
                    state.dispatch(.moduleSpecific(id: "plane.createDerivative", payload: object.id.uuidString))
                } : nil,
                onFindRoots: object.type == .function ? {
                    state.dispatch(.moduleSpecific(id: "plane.findRoots", payload: object.id.uuidString))
                } : nil,
                semanticIntentAdapter: state.semanticIntentAdapter,
                geometryResolver: state.geometryPresentationResolver,
                formulaDisplayConfiguration: state.effectiveReadOnlyFormulaDisplayConfiguration
            )
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("对象区")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(primaryText)

            Spacer(minLength: 0)

            if let onToggleFullscreen {
                if isFullscreen {
                    Button(action: onToggleFullscreen) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .background(.thinMaterial, in: Circle())
                    .foregroundStyle(primaryText)
                    .accessibilityLabel("退出全屏对象区")
                    .keyboardShortcut(.cancelAction)
                } else {
                    Button(action: onToggleFullscreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .background(.thinMaterial, in: Circle())
                    .foregroundStyle(primaryText)
                    .accessibilityLabel("全屏对象区")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("暂无对象")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(primaryText.opacity(0.88))

            Text("输入表达式或使用工具开始创作")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
        )
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
    }

    private var objectPanelTheme: WorkspaceTheme {
        var theme = WorkspaceTheme.sidePanel
        theme.darkPanelOpacity = AlgebraObjectPanelVisualMetrics.panelDarkOpacity
        theme.lightPanelOpacity = AlgebraObjectPanelVisualMetrics.panelLightOpacity
        theme.darkStrokeOpacity = AlgebraObjectPanelVisualMetrics.panelStrokeDarkOpacity
        theme.lightStrokeOpacity = AlgebraObjectPanelVisualMetrics.panelStrokeLightOpacity
        theme.darkShadowOpacity = AlgebraObjectPanelVisualMetrics.panelShadowDarkOpacity
        theme.lightShadowOpacity = AlgebraObjectPanelVisualMetrics.panelShadowLightOpacity
        return theme
    }
}

public enum AlgebraObjectPanelVisualMetrics {
    public static let panelDarkOpacity: Double = 0.08
    public static let panelLightOpacity: Double = 0.14
    public static let panelStrokeDarkOpacity: Double = 0.06
    public static let panelStrokeLightOpacity: Double = 0.08
    public static let panelShadowDarkOpacity: Double = 0.08
    public static let panelShadowLightOpacity: Double = 0.035
}

public enum AlgebraObjectPanelLayoutMetrics {
    public static let headerHeight: CGFloat = 24
    public static let headerToContentSpacing: CGFloat = 12
    public static let sectionHeaderHeight: CGFloat = 22
    public static let sectionHeaderToContentSpacing: CGFloat = 8
    public static let sectionSpacing: CGFloat = 14
    public static let normalRowHeight: CGFloat = 88
    public static let sliderRowHeight: CGFloat = 98
    public static let rowHeight: CGFloat = normalRowHeight
    public static let rowSpacing: CGFloat = 10
    public static let panelVerticalPadding: CGFloat = 28
    public static let emptyStateHeight: CGFloat = 70
    public static let minimumPanelHeight: CGFloat = 150

    public static func contentHeight(for objectCount: Int) -> CGFloat {
        if objectCount <= 0 {
            return panelVerticalPadding + headerHeight + headerToContentSpacing + emptyStateHeight
        }
        let rows = CGFloat(objectCount) * rowHeight
        let spacing = CGFloat(max(0, objectCount - 1)) * rowSpacing
        return panelVerticalPadding + headerHeight + headerToContentSpacing + rows + spacing
    }

    public static func contentHeight(for objects: [MathObject]) -> CGFloat {
        if objects.isEmpty {
            return contentHeight(for: 0)
        }
        let sections = AlgebraObjectPanelSection.makeSections(from: objects)
        let sectionHeights = sections.reduce(CGFloat.zero) { partial, section in
            let rows = section.objects.reduce(CGFloat.zero) { rowPartial, object in
                rowPartial + rowHeight(for: object)
            }
            let spacing = CGFloat(max(0, section.objects.count - 1)) * rowSpacing
            return partial + sectionHeaderHeight + sectionHeaderToContentSpacing + rows + spacing
        }
        let sectionGaps = CGFloat(max(0, sections.count - 1)) * sectionSpacing
        return panelVerticalPadding + headerHeight + headerToContentSpacing + sectionHeights + sectionGaps
    }

    public static func rowHeight(for object: MathObject) -> CGFloat {
        object.type == .parameter ? sliderRowHeight : normalRowHeight
    }
}

private struct ParameterObjectRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    public var object: MathObject
    public var isSelected: Bool
    public var isPlaying: Bool
    public var onSelect: () -> Void
    public var onTogglePlayback: () -> Void
    public var onValueChange: (Double) -> Void
    public var onUpdateSettings: (SliderSettings) -> Void
    public var onOpenCustomSettings: () -> Void
    public var onDelete: () -> Void
    public var onOpenSettings: () -> Void

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(ColorToken.resolvedColor(from: object.style.colorToken, fallback: .indigo))
                        .frame(width: 9, height: 9)

                    Text("\(object.name) = \(format(value))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(primaryText)

                    Spacer(minLength: 0)

                    HStack(spacing: 6) {
                        Button(action: onTogglePlayback) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.08))
                                )
                        }
                        .buttonStyle(.plain)

                        Menu {
                            rangePresetMenu
                            stepPresetMenu
                            precisionPresetMenu
                            playbackModePresetMenu
                            loopModePresetMenu
                            speedPresetMenu

                            Button {
                                onOpenCustomSettings()
                            } label: {
                                Label("自定义设置...", systemImage: "slider.horizontal.3")
                            }

                            Button("重置为默认设置") {
                                onUpdateSettings(SliderSettings.default)
                            }

                            Divider()

                            Button {
                                onOpenSettings()
                            } label: {
                                Label("打开对象设置", systemImage: "slider.horizontal.3")
                            }

                            Divider()

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
                            onSelect()
                        })
                        .buttonStyle(.plain)
                    }
                }

                Slider(
                    value: Binding(
                        get: { value },
                        set: onValueChange
                    ),
                    in: sliderRange,
                    step: max(currentSettings.step, 0.000_001)
                )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(selectionBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var value: Double {
        object.parameterValue ?? 1
    }

    private var sliderRange: ClosedRange<Double> {
        let minValue = currentSettings.min
        let maxValue = currentSettings.max
        return min(minValue, maxValue)...max(minValue, maxValue)
    }

    private var currentSettings: SliderSettings {
        if let settings = object.sliderSettings {
            return settings
        }
        var settings = SliderSettings.default
        if let minValue = object.parameterMin {
            settings.min = minValue
        }
        if let maxValue = object.parameterMax {
            settings.max = maxValue
        }
        return settings
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
    }

    @ViewBuilder
    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? Color.accentColor.opacity(colorScheme == .dark ? 0.16 : 0.10) : Color.white.opacity(colorScheme == .dark ? 0.05 : 0.14))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.16) : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.14), lineWidth: 0.8)
            }
    }

    private func format(_ value: Double) -> String {
        let precision = max(0, min(currentSettings.precision, 8))
        let factor = pow(10.0, Double(precision))
        let rounded = (value * factor).rounded() / factor
        if precision == 0 || rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(format: "%.\(precision)f", rounded)
    }

    private func updateSettings(_ mutate: (inout SliderSettings) -> Void) {
        var settings = currentSettings
        mutate(&settings)
        onUpdateSettings(settings)
    }

    private func applyRange(min: Double, max: Double) {
        updateSettings {
            $0.min = min
            $0.max = max
        }
    }

    private func applyStep(_ step: Double) {
        updateSettings { $0.step = step }
    }

    private func applyPrecision(_ precision: Int) {
        updateSettings { $0.precision = precision }
    }

    private func applySpeed(_ speed: Double) {
        updateSettings { $0.speed = speed }
    }

    private func applyMode(_ mode: SliderPlaybackMode) {
        updateSettings { $0.playbackMode = mode }
    }

    private func applyLoopMode(_ mode: SliderPlaybackLoopMode) {
        updateSettings { $0.playbackLoopMode = mode }
    }

    private func presetLabel(_ title: String, selected: Bool) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: "checkmark")
                .opacity(selected ? 1 : 0)
        }
    }

    private var rangePresetMenu: some View {
        Menu("范围") {
            Button(action: { applyRange(min: -10, max: 10) }) { presetLabel("[-10, 10]", selected: SliderSettingsPresetMatcher.rangeMatches(currentSettings, min: -10, max: 10)) }
            Button(action: { applyRange(min: -5, max: 5) }) { presetLabel("[-5, 5]", selected: SliderSettingsPresetMatcher.rangeMatches(currentSettings, min: -5, max: 5)) }
            Button(action: { applyRange(min: 0, max: 1) }) { presetLabel("[0, 1]", selected: SliderSettingsPresetMatcher.rangeMatches(currentSettings, min: 0, max: 1)) }
            Button(action: { applyRange(min: 0, max: 2 * Double.pi) }) { presetLabel("[0, 2π]", selected: SliderSettingsPresetMatcher.rangeMatches(currentSettings, min: 0, max: 2 * Double.pi)) }
        }
    }

    private var stepPresetMenu: some View {
        Menu("步长") {
            Button(action: { applyStep(0.01) }) { presetLabel("0.01", selected: SliderSettingsPresetMatcher.stepMatches(currentSettings, step: 0.01)) }
            Button(action: { applyStep(0.1) }) { presetLabel("0.1", selected: SliderSettingsPresetMatcher.stepMatches(currentSettings, step: 0.1)) }
            Button(action: { applyStep(0.5) }) { presetLabel("0.5", selected: SliderSettingsPresetMatcher.stepMatches(currentSettings, step: 0.5)) }
            Button(action: { applyStep(1.0) }) { presetLabel("1.0", selected: SliderSettingsPresetMatcher.stepMatches(currentSettings, step: 1.0)) }
        }
    }

    private var precisionPresetMenu: some View {
        Menu("精度") {
            Button(action: { applyPrecision(0) }) { presetLabel("0", selected: SliderSettingsPresetMatcher.precisionMatches(currentSettings, precision: 0)) }
            Button(action: { applyPrecision(1) }) { presetLabel("1", selected: SliderSettingsPresetMatcher.precisionMatches(currentSettings, precision: 1)) }
            Button(action: { applyPrecision(2) }) { presetLabel("2", selected: SliderSettingsPresetMatcher.precisionMatches(currentSettings, precision: 2)) }
            Button(action: { applyPrecision(3) }) { presetLabel("3", selected: SliderSettingsPresetMatcher.precisionMatches(currentSettings, precision: 3)) }
            Button(action: { applyPrecision(4) }) { presetLabel("4", selected: SliderSettingsPresetMatcher.precisionMatches(currentSettings, precision: 4)) }
        }
    }

    private var playbackModePresetMenu: some View {
        Menu("播放方向") {
            Button(action: { applyMode(.increasing) }) { presetLabel("递增", selected: SliderSettingsPresetMatcher.playbackModeMatches(currentSettings, mode: .increasing)) }
            Button(action: { applyMode(.decreasing) }) { presetLabel("递减", selected: SliderSettingsPresetMatcher.playbackModeMatches(currentSettings, mode: .decreasing)) }
            Button(action: { applyMode(.pingPong) }) { presetLabel("Ping-Pong", selected: SliderSettingsPresetMatcher.playbackModeMatches(currentSettings, mode: .pingPong)) }
        }
    }

    private var loopModePresetMenu: some View {
        Menu("循环策略") {
            Button(action: { applyLoopMode(.loop) }) { presetLabel("循环", selected: SliderSettingsPresetMatcher.loopModeMatches(currentSettings, mode: .loop)) }
            Button(action: { applyLoopMode(.clamp) }) { presetLabel("钳制", selected: SliderSettingsPresetMatcher.loopModeMatches(currentSettings, mode: .clamp)) }
            Button(action: { applyLoopMode(.pingPong) }) { presetLabel("反弹", selected: SliderSettingsPresetMatcher.loopModeMatches(currentSettings, mode: .pingPong)) }
        }
    }

    private var speedPresetMenu: some View {
        Menu("播放速度") {
            Button(action: { applySpeed(0.5) }) { presetLabel("0.5x", selected: SliderSettingsPresetMatcher.speedMatches(currentSettings, speed: 0.5)) }
            Button(action: { applySpeed(1.0) }) { presetLabel("1x", selected: SliderSettingsPresetMatcher.speedMatches(currentSettings, speed: 1.0)) }
            Button(action: { applySpeed(2.0) }) { presetLabel("2x", selected: SliderSettingsPresetMatcher.speedMatches(currentSettings, speed: 2.0)) }
            Button(action: { applySpeed(4.0) }) { presetLabel("4x", selected: SliderSettingsPresetMatcher.speedMatches(currentSettings, speed: 4.0)) }
        }
    }
}

private struct SliderSettingsSheetItem: Identifiable {
    public let id: UUID
}

public struct SliderSettingsFormValidator {
    public enum ValidationError: Error, Equatable {
        case message(String)

        var message: String {
            switch self {
            case .message(let value):
                return value
            }
        }
    }

    public static func validateAndNormalize(
        minText: String,
        maxText: String,
        valueText: String,
        stepText: String,
        speedText: String,
        precision: Int,
        playbackMode: SliderPlaybackMode,
        playbackLoopMode: SliderPlaybackLoopMode
    ) -> Result<(settings: SliderSettings, value: Double), ValidationError> {
        guard let minValue = Double(minText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let maxValue = Double(maxText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .failure(.message("最小值和最大值必须是数字"))
        }
        guard minValue < maxValue else {
            return .failure(.message("最小值必须小于最大值"))
        }
        guard let stepValue = Double(stepText.trimmingCharacters(in: .whitespacesAndNewlines)), stepValue > 0 else {
            return .failure(.message("步长必须大于 0"))
        }
        guard let speedValue = Double(speedText.trimmingCharacters(in: .whitespacesAndNewlines)), speedValue > 0 else {
            return .failure(.message("速度必须大于 0"))
        }
        let inputValue = Double(valueText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? minValue
        let safePrecision = max(0, min(precision, 6))
        let settings = SliderSettings(
            min: minValue,
            max: maxValue,
            step: stepValue,
            precision: safePrecision,
            speed: speedValue,
            playbackMode: playbackMode,
            playbackLoopMode: playbackLoopMode
        )
        let clamped = min(max(inputValue, minValue), maxValue)
        let offset = (clamped - minValue) / stepValue
        let quantized = min(max(minValue + offset.rounded() * stepValue, minValue), maxValue)
        return .success((settings, quantized))
    }
}

public struct SliderSettingsPresetMatcher {
    private static let epsilon = 1e-9

    public static func rangeMatches(_ settings: SliderSettings, min: Double, max: Double) -> Bool {
        doubleEquals(settings.min, min) && doubleEquals(settings.max, max)
    }

    public static func stepMatches(_ settings: SliderSettings, step: Double) -> Bool {
        doubleEquals(settings.step, step)
    }

    public static func precisionMatches(_ settings: SliderSettings, precision: Int) -> Bool {
        settings.precision == precision
    }

    public static func speedMatches(_ settings: SliderSettings, speed: Double) -> Bool {
        doubleEquals(settings.speed, speed)
    }

    public static func playbackModeMatches(_ settings: SliderSettings, mode: SliderPlaybackMode) -> Bool {
        settings.playbackMode == mode
    }

    public static func loopModeMatches(_ settings: SliderSettings, mode: SliderPlaybackLoopMode) -> Bool {
        settings.playbackLoopMode == mode
    }

    private static func doubleEquals(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < epsilon
    }
}

private struct SliderSettingsSheet: View {
    public let object: MathObject
    public let onCancel: () -> Void
    public let onSave: (SliderSettings, Double) -> Void

    @State private var minText: String
    @State private var maxText: String
    @State private var valueText: String
    @State private var stepText: String
    @State private var speedText: String
    @State private var precision: Int
    @State private var playbackMode: SliderPlaybackMode
    @State private var playbackLoopMode: SliderPlaybackLoopMode
    @State private var errorMessage: String?

    public init(object: MathObject, onCancel: @escaping () -> Void, onSave: @escaping (SliderSettings, Double) -> Void) {
        self.object = object
        self.onCancel = onCancel
        self.onSave = onSave
        let settings = object.sliderSettings ?? .default
        _minText = State(initialValue: Self.formatNumber(settings.min))
        _maxText = State(initialValue: Self.formatNumber(settings.max))
        _valueText = State(initialValue: Self.formatNumber(object.parameterValue ?? settings.min))
        _stepText = State(initialValue: Self.formatNumber(settings.step))
        _speedText = State(initialValue: Self.formatNumber(settings.speed))
        _precision = State(initialValue: max(0, min(settings.precision, 6)))
        _playbackMode = State(initialValue: settings.playbackMode)
        _playbackLoopMode = State(initialValue: settings.playbackLoopMode)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Range") {
                    TextField("Min", text: $minText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Max", text: $maxText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Current Value", text: $valueText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                Section("Step / Precision") {
                    TextField("Step", text: $stepText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Picker("Precision", selection: $precision) {
                        ForEach(0...6, id: \.self) { digits in
                            Text("\(digits)").tag(digits)
                        }
                    }
                }

                Section("Playback") {
                    TextField("Speed", text: $speedText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif

                    Picker("Mode", selection: $playbackMode) {
                        Text("Increasing").tag(SliderPlaybackMode.increasing)
                        Text("Decreasing").tag(SliderPlaybackMode.decreasing)
                        Text("Ping-Pong").tag(SliderPlaybackMode.pingPong)
                    }

                    Picker("Loop", selection: $playbackLoopMode) {
                        Text("Loop").tag(SliderPlaybackLoopMode.loop)
                        Text("Clamp").tag(SliderPlaybackLoopMode.clamp)
                        Text("Ping-Pong").tag(SliderPlaybackLoopMode.pingPong)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
            .navigationTitle("Slider Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
#if os(iOS)
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset Defaults") {
                        applyDefaults()
                    }
                }
#endif
            }
        }
    }

    private func save() {
        switch SliderSettingsFormValidator.validateAndNormalize(
            minText: minText,
            maxText: maxText,
            valueText: valueText,
            stepText: stepText,
            speedText: speedText,
            precision: precision,
            playbackMode: playbackMode,
            playbackLoopMode: playbackLoopMode
        ) {
        case .success(let payload):
            errorMessage = nil
            onSave(payload.settings, payload.value)
        case .failure(let error):
            errorMessage = error.message
        }
    }

    private func applyDefaults() {
        let defaults = SliderSettings.default
        minText = Self.formatNumber(defaults.min)
        maxText = Self.formatNumber(defaults.max)
        valueText = Self.formatNumber(object.parameterValue ?? defaults.min)
        stepText = Self.formatNumber(defaults.step)
        speedText = Self.formatNumber(defaults.speed)
        precision = defaults.precision
        playbackMode = defaults.playbackMode
        playbackLoopMode = defaults.playbackLoopMode
        errorMessage = nil
    }

    private static func formatNumber(_ value: Double) -> String {
        let intValue = Int(value)
        if value == Double(intValue) {
            return "\(intValue)"
        }
        return String(value)
    }
}
