import SwiftUI
#if canImport(UIKit)
import UIKit

public struct MathPlainTextField: UIViewRepresentable {
    public var placeholder: String
    @Binding var text: String
    public var cursorIndex: Binding<Int>?
    public var selectedRange: Binding<Range<Int>?>?
    public var suppressSystemKeyboard: Bool = false
    public var autoFocus: Bool = false

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        if suppressSystemKeyboard {
            textField.inputView = UIView(frame: .zero)
        }
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.cursorIndex = cursorIndex
        context.coordinator.selectedRange = selectedRange

        if suppressSystemKeyboard && uiView.inputView == nil {
            uiView.inputView = UIView(frame: .zero)
        }

        if uiView.text != text {
            context.coordinator.performProgrammaticUpdate {
                uiView.text = text
            }
        }

        applySelection(to: uiView, coordinator: context.coordinator)

        if autoFocus && !uiView.isFirstResponder {
            let coordinator = context.coordinator
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                applySelection(to: uiView, coordinator: coordinator)
            }
        }
    }

    private func applySelection(to uiView: UITextField, coordinator: Coordinator) {
        guard let cursorIndex, let selectedRange else { return }
        let targetRange = selectedRange.wrappedValue ?? cursorIndex.wrappedValue..<cursorIndex.wrappedValue
        coordinator.setSelection(targetRange, in: uiView)
        DispatchQueue.main.async {
            coordinator.setSelection(targetRange, in: uiView)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, cursorIndex: cursorIndex, selectedRange: selectedRange)
    }

    public final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var cursorIndex: Binding<Int>?
        var selectedRange: Binding<Range<Int>?>?
        private var isProgrammaticUpdate = false

        init(text: Binding<String>, cursorIndex: Binding<Int>?, selectedRange: Binding<Range<Int>?>?) {
            self._text = text
            self.cursorIndex = cursorIndex
            self.selectedRange = selectedRange
        }

        func performProgrammaticUpdate(_ update: () -> Void) {
            isProgrammaticUpdate = true
            update()
            isProgrammaticUpdate = false
        }

        @objc func textDidChange(_ sender: UITextField) {
            text = sender.text ?? ""
            reportSelection(from: sender)
        }

        public func textFieldDidChangeSelection(_ textField: UITextField) {
            guard !isProgrammaticUpdate else { return }
            reportSelection(from: textField)
        }

        func setSelection(_ range: Range<Int>, in textField: UITextField) {
            let textCount = textField.text?.count ?? 0
            let lower = max(0, min(textCount, range.lowerBound))
            let upper = max(lower, min(textCount, range.upperBound))
            let clampedRange = lower..<upper

            guard currentSelectionRange(in: textField) != clampedRange,
                  let start = textField.position(from: textField.beginningOfDocument, offset: clampedRange.lowerBound),
                  let end = textField.position(from: textField.beginningOfDocument, offset: clampedRange.upperBound) else { return }

            isProgrammaticUpdate = true
            textField.selectedTextRange = textField.textRange(from: start, to: end)
            isProgrammaticUpdate = false
        }

        private func reportSelection(from textField: UITextField) {
            guard let range = currentSelectionRange(in: textField) else { return }
            cursorIndex?.wrappedValue = range.upperBound
            selectedRange?.wrappedValue = range
        }

        private func currentSelectionRange(in textField: UITextField) -> Range<Int>? {
            guard let selection = textField.selectedTextRange else { return nil }
            let start = textField.offset(from: textField.beginningOfDocument, to: selection.start)
            let end = textField.offset(from: textField.beginningOfDocument, to: selection.end)
            return start..<end
        }
    }
}
#endif
