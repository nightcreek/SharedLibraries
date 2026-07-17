import XCTest
import SwiftUI
import EMathicaMathInputCore
import EMathicaMathInputUI

final class MathInputKeyboardAdoptionTests: XCTestCase {
    @MainActor
    func testWorkspacePackageCanInitializeMathInputKeyboardViewWithActionForwarding() {
        let view = MathInputKeyboardView { (_: KeyboardAction) in }
        XCTAssertNotNil(view)
    }

    func testKeyboardIntentMappingPreservesWorkspaceEditingCommands() {
        XCTAssertEqual(MathKeyboardIntent.action(.deleteBackward).keyboardAction, .deleteBackward)
        XCTAssertEqual(MathKeyboardIntent.action(.moveLeft).keyboardAction, .moveLeft)
        XCTAssertEqual(MathKeyboardIntent.action(.moveRight).keyboardAction, .moveRight)
        XCTAssertEqual(MathKeyboardIntent.action(.submit).keyboardAction, .submit)
        XCTAssertEqual(MathKeyboardIntent.input(.control(.nextSlot)).keyboardAction, .tab)
    }

    func testUndoAndRedoRemainUnsupportedByActionForwardingHelper() {
        XCTAssertNil(MathKeyboardIntent.input(.control(.undo)).keyboardAction)
        XCTAssertNil(MathKeyboardIntent.input(.control(.redo)).keyboardAction)
    }
}
