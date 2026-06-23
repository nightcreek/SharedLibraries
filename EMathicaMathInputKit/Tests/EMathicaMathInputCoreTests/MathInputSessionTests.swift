import XCTest
@testable import EMathicaMathInputCore

final class MathInputSessionTests: XCTestCase {
    func testSessionApplyExportImportAndReset() throws {
        let session = MathInputSession()

        session.apply(.insertCharacter("x"))

        XCTAssertFalse(session.sourceText.isEmpty)
        XCTAssertFalse(session.displayLatex.isEmpty)
        XCTAssertFalse(session.computeExpression.isEmpty)

        let exported = try session.exportEditorStateJSON(prettyPrinted: true)
        XCTAssertFalse(exported.isEmpty)

        let imported = MathInputSession()
        try imported.importEditorStateJSON(exported)
        XCTAssertEqual(imported.sourceText, session.sourceText)

        imported.reset()
        XCTAssertTrue(imported.sourceText.isEmpty)
    }
}
