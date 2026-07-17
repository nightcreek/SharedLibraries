import XCTest
@testable import EMathicaFormulaKeyboardCore

final class FormulaKeyboardCoreMarkerTests: XCTestCase {
    func testVersionMarkerIsAvailable() {
        XCTAssertEqual(EMathicaFormulaKeyboardCoreMarker.version, "0.1.0-dev")
    }

    func testFormulaKeyboardIdentifierRoundTripsThroughCodable() throws {
        let identifier = FormulaKeyboardIdentifier(rawValue: "builtin.standard")
        let data = try JSONEncoder().encode(identifier)
        let decoded = try JSONDecoder().decode(FormulaKeyboardIdentifier.self, from: data)

        XCTAssertEqual(decoded, identifier)
    }

    func testFormulaKeyIdentifierSupportsEqualityAndHashing() {
        let lhs = FormulaKeyIdentifier(rawValue: "key.sqrt")
        let rhs = FormulaKeyIdentifier(rawValue: "key.sqrt")
        let other = FormulaKeyIdentifier(rawValue: "key.frac")

        XCTAssertEqual(lhs, rhs)
        XCTAssertNotEqual(lhs, other)
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
    }

    func testFormulaKeyboardVersionRoundTripsThroughCodable() throws {
        let version = FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        let data = try JSONEncoder().encode(version)
        let decoded = try JSONDecoder().decode(FormulaKeyboardVersion.self, from: data)

        XCTAssertEqual(decoded, version)
    }

    func testFormulaKeyboardMetadataRoundTripsThroughCodable() throws {
        let metadata = FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard Keyboard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )
        let data = try JSONEncoder().encode(metadata)
        let decoded = try JSONDecoder().decode(FormulaKeyboardMetadata.self, from: data)

        XCTAssertEqual(decoded, metadata)
    }

    func testPrimitiveProtocolConformanceRemainsAvailableForStableValueTypes() {
        func assertPrimitive<T: FormulaKeyboardPrimitive>(_ value: T) -> T {
            value
        }

        let metadata = FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard Keyboard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )

        XCTAssertEqual(assertPrimitive(metadata), metadata)
    }
}
