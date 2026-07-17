import EMathicaMathInputCore
import SwiftUI
#if canImport(UIKit)
import UIKit

public struct HardwareKeyboardCaptureView: UIViewRepresentable {
    public var isFocused: Bool
    public var onAction: (KeyboardAction) -> Void

    public func makeUIView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onAction = onAction
        return view
    }

    public func updateUIView(_ uiView: KeyCaptureView, context: Context) {
        uiView.onAction = onAction
        uiView.wantsFocus = isFocused
        if isFocused && uiView.window != nil && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                _ = uiView.becomeFirstResponder()
            }
        } else if !isFocused && uiView.isFirstResponder {
            DispatchQueue.main.async {
                _ = uiView.resignFirstResponder()
            }
        }
    }
}

public class KeyCaptureView: UIView {
    public var onAction: ((KeyboardAction) -> Void)?
    public var wantsFocus: Bool = false

    public override var canBecomeFirstResponder: Bool { true }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        if wantsFocus && !isFirstResponder {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.wantsFocus && self.window != nil {
                    _ = self.becomeFirstResponder()
                }
            }
        }
    }

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            guard let key = press.key, let action = KeyboardHardwareMapper.map(key: key) else { continue }
            onAction?(action)
            handled = true
        }
        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }
}

public enum KeyboardHardwareMapper {
    public static func map(key: UIKey) -> KeyboardAction? {
        map(
            keyCode: key.keyCode,
            characters: key.characters,
            charactersIgnoringModifiers: key.charactersIgnoringModifiers,
            modifierFlags: key.modifierFlags
        )
    }

    public static func map(
        keyCode: UIKeyboardHIDUsage,
        characters: String,
        charactersIgnoringModifiers: String,
        modifierFlags: UIKeyModifierFlags
    ) -> KeyboardAction? {
        let descriptor = HardwareKeyboardDescriptor(
            keyCode: Int(keyCode.rawValue),
            characters: characters,
            charactersIgnoringModifiers: charactersIgnoringModifiers,
            modifiers: modifiers(from: modifierFlags)
        )
        return HardwareKeyboardSemanticMapper().intent(for: descriptor)?.keyboardAction
    }

    private static func modifiers(from flags: UIKeyModifierFlags) -> HardwareKeyboardModifiers {
        var modifiers: HardwareKeyboardModifiers = []
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        return modifiers
    }

}
#endif
