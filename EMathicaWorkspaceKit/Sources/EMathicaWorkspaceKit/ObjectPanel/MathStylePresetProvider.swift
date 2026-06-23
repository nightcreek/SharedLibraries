import EMathicaThemeKit
import EMathicaMathCore
import Foundation

public struct MathStylePresetProvider {
    public struct ColorPreset: Equatable, Hashable {
        let title: String
        let token: ColorToken
    }

    public struct NumericPreset: Equatable, Hashable, Sendable {
        let title: String
        let value: Double
    }

    public struct LineStylePreset: Equatable, Hashable, Sendable {
        let title: String
        let value: MathLineStyle
    }

    static nonisolated(unsafe) let colorPresets: [ColorPreset] = [
        .init(title: "蓝色", token: .blue),
        .init(title: "红色", token: .red),
        .init(title: "橙色", token: .orange),
        .init(title: "绿色", token: .green),
        .init(title: "紫色", token: .purple),
        .init(title: "青色", token: .cyan),
        .init(title: "白色", token: .white)
    ]

    public static let lineWidthPresets: [NumericPreset] = [
        .init(title: "1", value: 1),
        .init(title: "2", value: 2),
        .init(title: "3", value: 3),
        .init(title: "5", value: 5)
    ]

    public static let opacityPresets: [NumericPreset] = [
        .init(title: "25%", value: 0.25),
        .init(title: "50%", value: 0.5),
        .init(title: "75%", value: 0.75),
        .init(title: "100%", value: 1.0)
    ]

    public static let pointSizePresets: [NumericPreset] = [
        .init(title: "4", value: 4),
        .init(title: "6", value: 6),
        .init(title: "8", value: 8),
        .init(title: "12", value: 12)
    ]

    public static let lineStylePresets: [LineStylePreset] = [
        .init(title: "实线", value: .solid),
        .init(title: "虚线", value: .dashed)
    ]
}
