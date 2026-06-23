import EMathicaThemeKit
import EMathicaMathCore
import SwiftUI

public struct ObjectInspectorButton: View {
    public var action: () -> Void

    public var body: some View {
        Button(action: action) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 42, height: 42)
        }
        .buttonStyle(.bordered)
        .background {
            if #available(iOS 26.0, macOS 16.0, *) {
                Color.clear
                    .glassEffect(.regular.tint(Color.white.opacity(0.03)).interactive(), in: .rect(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
