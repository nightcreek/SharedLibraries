import EMathicaMathInputCore
import EMathicaThemeKit
import SwiftUI

struct MathInputKeyboardKeyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    let key: MathKeyboardKey
    let style: MathKeyboardStyle
    let action: (MathKeyboardKey) -> Void

    private var visualRole: MathInputKeyboardKeyVisualRole {
        MathInputKeyboardStyleBridge.keyVisualRole(for: key)
    }

    var body: some View {
        Button {
            action(key)
        } label: {
            MathInputKeyboardLabelView(
                key: key,
                style: style,
                visualRole: visualRole
            )
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                MathInputKeyboardStyleBridge.keyBackground(
                    style: style,
                    role: visualRole,
                    colorScheme: colorScheme,
                    isPressed: isPressed
                )
            }
            .contentShape(RoundedRectangle(cornerRadius: style.key.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityLabel(Text(key.accessibilityLabel ?? key.id))
    }
}
