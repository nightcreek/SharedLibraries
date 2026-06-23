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
        let action = map(
            keyCode: key.keyCode,
            characters: key.characters,
            charactersIgnoringModifiers: key.charactersIgnoringModifiers,
            modifierFlags: key.modifierFlags
        )
#if DEBUG
        debugLog(key: key, action: action)
#endif
        return action
    }

    public static func map(
        keyCode: UIKeyboardHIDUsage,
        characters: String,
        charactersIgnoringModifiers: String,
        modifierFlags: UIKeyModifierFlags
    ) -> KeyboardAction? {
        if modifierFlags.contains(.command) {
            // Let higher-level shortcut handlers or local editor undo/redo handle command combos.
            // We must not degrade Cmd+Z / Cmd+Shift+Z / Cmd+Y into plain character input.
            return nil
        }
        if keyCode == .keyboard6, modifierFlags.contains(.shift) {
            return .insertTemplate(.superscript)
        }
        if keyCode == .keyboardReturnOrEnter {
            return .submit
        }
        if keyCode == .keyboardDeleteOrBackspace {
            return .deleteBackward
        }
        if keyCode == .keyboardDeleteForward {
            return .deleteForward
        }
        if keyCode == .keyboardTab {
            if modifierFlags.contains(.shift) {
                return .shiftTab
            }
            return .tab
        }
        if keyCode == .keyboardLeftArrow {
            return .moveLeft
        }
        if keyCode == .keyboardRightArrow {
            return .moveRight
        }
        if keyCode == .keyboardUpArrow {
            return .moveUp
        }
        if keyCode == .keyboardDownArrow {
            return .moveDown
        }
        if keyCode == .keyboardEscape {
            return .cancel
        }

        // Printable characters must respect modifier result first.
        let raw = characters
        let fallback = charactersIgnoringModifiers
        let value = raw.isEmpty ? fallback : raw
        if value == "^" {
            return .insertTemplate(.superscript)
        }
        if value.isEmpty {
            return nil
        }

        if let action = mapOperator(value) {
            return action
        }
        return .insertCharacter(value)
    }

    private static func mapOperator(_ value: String) -> KeyboardAction? {
        switch value {
        case "+", "-", "=", "*", "/", "<", ">", ",":
            return .insertOperator(value)
        default:
            return nil
        }
    }

#if DEBUG
    private static func debugLog(key: UIKey, action: KeyboardAction?) {
        let hasShift = key.modifierFlags.contains(.shift)
        print("[HardwareKeyboard] keyCode=\(key.keyCode.rawValue) characters=\(key.characters.debugDescription) charactersIgnoringModifiers=\(key.charactersIgnoringModifiers.debugDescription) shift=\(hasShift) action=\(String(describing: action))")
    }
#endif
}
#endif
