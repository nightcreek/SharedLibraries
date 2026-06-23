import SwiftUI

public struct ModuleAssetIconView: View {
    public init(moduleID: String) { self.moduleID = moduleID }
    public let moduleID: String

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.10))

            Image(iconAssetName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .padding(6)
        }
        .frame(width: 36, height: 36)
    }

    private var iconAssetName: String {
        switch moduleID {
        case "plane":
            return "plane_calculator"
        case "space":
            return "space_calculator"
        case "modeling":
            return "modeling"
        case "music":
            return "music"
        case "data":
            return "data_analysis"
        case "notes":
            return "notes_formula"
        default:
            return "plane_calculator"
        }
    }
}
