import XCTest
@testable import EMathicaMathInputCore

final class HardwareKeyboardSemanticMapperTests: XCTestCase {
    private let mapper = HardwareKeyboardSemanticMapper()

    func testMapsCharacterInput() {
        let intent = mapper.intent(
            for: HardwareKeyboardDescriptor(
                characters: "x",
                charactersIgnoringModifiers: "x"
            )
        )

        XCTAssertEqual(intent, .input(.char("x")))
    }

    func testMapsNumberInput() {
        let intent = mapper.intent(
            for: HardwareKeyboardDescriptor(
                characters: "2",
                charactersIgnoringModifiers: "2"
            )
        )

        XCTAssertEqual(intent, .input(.number("2")))
    }

    func testMapsDeleteBackward() {
        let intent = mapper.intent(
            for: HardwareKeyboardDescriptor(keyCode: 42)
        )

        XCTAssertEqual(intent, .action(.deleteBackward))
    }

    func testMapsReturnToSubmit() {
        let intent = mapper.intent(
            for: HardwareKeyboardDescriptor(keyCode: 40)
        )

        XCTAssertEqual(intent, .action(.submit))
    }

    func testMapsArrowKeys() {
        XCTAssertEqual(mapper.intent(for: HardwareKeyboardDescriptor(keyCode: 80)), .action(.moveLeft))
        XCTAssertEqual(mapper.intent(for: HardwareKeyboardDescriptor(keyCode: 79)), .action(.moveRight))
        XCTAssertEqual(mapper.intent(for: HardwareKeyboardDescriptor(keyCode: 82)), .action(.moveUp))
        XCTAssertEqual(mapper.intent(for: HardwareKeyboardDescriptor(keyCode: 81)), .action(.moveDown))
    }
}
