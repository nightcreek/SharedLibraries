import SwiftUI

public struct ModuleIconView: View {
    public init(iconName: String, accent: Color = .blue) { self.iconName = iconName; self.accent = accent }
    public let iconName: String
    public let accent: Color

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.14))

            Image(iconName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .padding(6)
        }
        .frame(width: 36, height: 36)
    }
}
