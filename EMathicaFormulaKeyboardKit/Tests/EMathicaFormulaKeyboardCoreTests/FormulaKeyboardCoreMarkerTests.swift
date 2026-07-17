import XCTest
@testable import EMathicaFormulaKeyboardCore

final class FormulaKeyboardCoreMarkerTests: XCTestCase {
    func testVersionMarkerIsAvailable() {
        XCTAssertEqual(EMathicaFormulaKeyboardCoreMarker.version, "0.1.0-dev")
    }

    func testFormulaKeyboardIdentifierRoundTripsThroughCodable() throws {
        let identifier = try FormulaKeyboardIdentifier(rawValue: "builtin.standard")
        let data = try JSONEncoder().encode(identifier)
        let decoded = try JSONDecoder().decode(FormulaKeyboardIdentifier.self, from: data)

        XCTAssertEqual(decoded, identifier)
    }

    func testFormulaKeyIdentifierSupportsEqualityAndHashing() throws {
        let lhs = try FormulaKeyIdentifier(rawValue: "key.sqrt")
        let rhs = try FormulaKeyIdentifier(rawValue: "key.sqrt")
        let other = try FormulaKeyIdentifier(rawValue: "key.frac")

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
        let metadata = try FormulaKeyboardMetadata(
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

        let metadata = try? FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard Keyboard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )

        XCTAssertEqual(assertPrimitive(metadata!), metadata!)
    }

    func testIdentifierRejectsBlankValues() {
        XCTAssertThrowsError(try FormulaKeyboardIdentifier(rawValue: "   "))
        XCTAssertThrowsError(try FormulaKeyIdentifier(rawValue: "\n"))
        XCTAssertThrowsError(try FormulaKeyboardPageIdentifier(rawValue: ""))
        XCTAssertThrowsError(try FormulaKeyboardSectionIdentifier(rawValue: " "))
        XCTAssertThrowsError(try FormulaKeyboardRowIdentifier(rawValue: "\t"))
    }

    func testPresentationRoundTripsThroughCodable() throws {
        let presentation = FormulaKeyPresentation.formulaSource(
            try FormulaKeyboardFormulaSource(latexSource: "\\sqrt{x}")
        )

        let data = try JSONEncoder().encode(presentation)
        let decoded = try JSONDecoder().decode(FormulaKeyPresentation.self, from: data)

        XCTAssertEqual(decoded, presentation)
    }

    func testIntentRoundTripsThroughCodable() throws {
        let intent = FormulaKeyIntent.semanticToken(
            try FormulaSemanticToken(namespace: "builtin", name: "sqrt")
        )

        let data = try JSONEncoder().encode(intent)
        let decoded = try JSONDecoder().decode(FormulaKeyIntent.self, from: data)

        XCTAssertEqual(decoded, intent)
    }

    func testLayoutHintRejectsInvalidWidthWeight() {
        XCTAssertThrowsError(try FormulaKeyLayoutHint(widthWeight: 0))
        XCTAssertThrowsError(try FormulaKeyLayoutHint(widthWeight: -1))
    }

    func testDefinitionRejectsEmptyPages() throws {
        let metadata = try FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )

        XCTAssertThrowsError(
            try FormulaKeyboardDefinition(
                metadata: metadata,
                defaultPageID: FormulaKeyboardPageIdentifier(rawValue: "page.main"),
                pages: []
            )
        )
    }

    func testDefinitionRejectsMissingDefaultPage() throws {
        let metadata = try FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )
        let key = FormulaKeyDefinition(
            id: try FormulaKeyIdentifier(rawValue: "key.sqrt"),
            presentation: .text(.verbatim("sqrt")),
            intent: .semanticToken(try FormulaSemanticToken(namespace: "builtin", name: "sqrt")),
            layoutHint: try FormulaKeyLayoutHint(widthWeight: 1)
        )
        let row = try FormulaKeyboardRowDefinition(
            id: FormulaKeyboardRowIdentifier(rawValue: "row.main"),
            keys: [key]
        )
        let section = try FormulaKeyboardSectionDefinition(
            id: FormulaKeyboardSectionIdentifier(rawValue: "section.main"),
            rows: [row]
        )
        let page = try FormulaKeyboardPageDefinition(
            id: FormulaKeyboardPageIdentifier(rawValue: "page.main"),
            sections: [section]
        )

        XCTAssertThrowsError(
            try FormulaKeyboardDefinition(
                metadata: metadata,
                defaultPageID: FormulaKeyboardPageIdentifier(rawValue: "page.missing"),
                pages: [page]
            )
        )
    }

    func testDefinitionRejectsDuplicateIdentifiersAcrossHierarchy() throws {
        let metadata = try FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )
        let keyA = FormulaKeyDefinition(
            id: try FormulaKeyIdentifier(rawValue: "key.dup"),
            presentation: .text(.verbatim("a")),
            intent: .semanticToken(try FormulaSemanticToken(namespace: "builtin", name: "a")),
            layoutHint: try FormulaKeyLayoutHint(widthWeight: 1)
        )
        let keyB = FormulaKeyDefinition(
            id: try FormulaKeyIdentifier(rawValue: "key.dup"),
            presentation: .text(.verbatim("b")),
            intent: .semanticToken(try FormulaSemanticToken(namespace: "builtin", name: "b")),
            layoutHint: try FormulaKeyLayoutHint(widthWeight: 1)
        )
        let row = try FormulaKeyboardRowDefinition(
            id: FormulaKeyboardRowIdentifier(rawValue: "row.main"),
            keys: [keyA, keyB]
        )
        let section = try FormulaKeyboardSectionDefinition(
            id: FormulaKeyboardSectionIdentifier(rawValue: "section.main"),
            rows: [row]
        )
        let page = try FormulaKeyboardPageDefinition(
            id: FormulaKeyboardPageIdentifier(rawValue: "page.main"),
            sections: [section]
        )

        XCTAssertThrowsError(
            try FormulaKeyboardDefinition(
                metadata: metadata,
                defaultPageID: FormulaKeyboardPageIdentifier(rawValue: "page.main"),
                pages: [page]
            )
        )
    }

    func testSectionRowAndPageRejectEmptyChildren() throws {
        let pageID = try FormulaKeyboardPageIdentifier(rawValue: "page.main")
        let sectionID = try FormulaKeyboardSectionIdentifier(rawValue: "section.main")
        let rowID = try FormulaKeyboardRowIdentifier(rawValue: "row.main")

        XCTAssertThrowsError(try FormulaKeyboardPageDefinition(id: pageID, sections: []))
        XCTAssertThrowsError(try FormulaKeyboardSectionDefinition(id: sectionID, rows: []))
        XCTAssertThrowsError(try FormulaKeyboardRowDefinition(id: rowID, keys: []))
    }

    func testDefinitionRoundTripsThroughCodable() throws {
        let metadata = try FormulaKeyboardMetadata(
            id: FormulaKeyboardIdentifier(rawValue: "builtin.standard"),
            name: "Standard",
            version: FormulaKeyboardVersion(major: 1, minor: 0, patch: 0)
        )
        let key = FormulaKeyDefinition(
            id: try FormulaKeyIdentifier(rawValue: "key.sqrt"),
            presentation: .formulaSource(try FormulaKeyboardFormulaSource(latexSource: "\\sqrt{x}")),
            intent: .semanticToken(try FormulaSemanticToken(namespace: "builtin", name: "sqrt")),
            layoutHint: try FormulaKeyLayoutHint(widthWeight: 2)
        )
        let row = try FormulaKeyboardRowDefinition(
            id: FormulaKeyboardRowIdentifier(rawValue: "row.main"),
            keys: [key]
        )
        let section = try FormulaKeyboardSectionDefinition(
            id: FormulaKeyboardSectionIdentifier(rawValue: "section.main"),
            rows: [row]
        )
        let page = try FormulaKeyboardPageDefinition(
            id: FormulaKeyboardPageIdentifier(rawValue: "page.main"),
            sections: [section]
        )
        let definition = try FormulaKeyboardDefinition(
            metadata: metadata,
            defaultPageID: FormulaKeyboardPageIdentifier(rawValue: "page.main"),
            pages: [page]
        )

        let data = try JSONEncoder().encode(definition)
        let decoded = try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: data)

        XCTAssertEqual(decoded, definition)
    }

    func testDecodedIdentifiersRejectLeadingTrailingAndBlankWhitespace() {
        let decoder = JSONDecoder()

        XCTAssertNoThrow(try decoder.decode(FormulaKeyboardIdentifier.self, from: Data(#""leading""#.utf8)))
        XCTAssertNoThrow(try decoder.decode(FormulaKeyboardIdentifier.self, from: Data(#""value""#.utf8)))
        XCTAssertThrowsError(try decoder.decode(FormulaKeyboardIdentifier.self, from: Data(#"" leading""#.utf8)))
        XCTAssertThrowsError(try decoder.decode(FormulaKeyboardIdentifier.self, from: Data(#""trailing ""#.utf8)))
        XCTAssertThrowsError(try decoder.decode(FormulaKeyboardIdentifier.self, from: Data(#""   ""#.utf8)))
        XCTAssertThrowsError(try decoder.decode(FormulaKeyboardIdentifier.self, from: Data(#""\nvalue""#.utf8)))
    }

    func testDecodedDefinitionRejectsEmptyPages() throws {
        let json = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": []
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(json.utf8)))
    }

    func testDecodedDefinitionRejectsMissingDefaultPage() {
        let json = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.missing",
          "pages": [
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.main",
                  "rows": [
                    {
                      "id": "row.main",
                      "keys": [
                        {
                          "id": "key.sqrt",
                          "presentation": { "text": { "verbatim": "sqrt" } },
                          "intent": { "semanticToken": { "namespace": "builtin", "name": "sqrt" } },
                          "layoutHint": 1
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(json.utf8)))
    }

    func testDecodedDefinitionRejectsDuplicatePageSectionRowAndKeyIdentifiers() {
        let duplicatePageJSON = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": [
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.a",
                  "rows": [
                    {
                      "id": "row.a",
                      "keys": [
                        {
                          "id": "key.a",
                          "presentation": { "text": { "verbatim": "a" } },
                          "intent": { "semanticToken": { "namespace": "builtin", "name": "a" } },
                          "layoutHint": 1
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.b",
                  "rows": [
                    {
                      "id": "row.b",
                      "keys": [
                        {
                          "id": "key.b",
                          "presentation": { "text": { "verbatim": "b" } },
                          "intent": { "semanticToken": { "namespace": "builtin", "name": "b" } },
                          "layoutHint": 1
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let duplicateSectionJSON = duplicatePageJSON.replacingOccurrences(of: "\"section.b\"", with: "\"section.a\"")
        let duplicateRowJSON = duplicatePageJSON.replacingOccurrences(of: "\"row.b\"", with: "\"row.a\"")
        let duplicateKeyJSON = duplicatePageJSON.replacingOccurrences(of: "\"key.b\"", with: "\"key.a\"")

        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(duplicatePageJSON.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(duplicateSectionJSON.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(duplicateRowJSON.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(duplicateKeyJSON.utf8)))
    }

    func testDecodedDefinitionRejectsEmptySectionsRowsAndKeys() {
        let emptySectionsJSON = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": [
            {
              "id": "page.main",
              "sections": []
            }
          ]
        }
        """

        let emptyRowsJSON = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": [
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.main",
                  "rows": []
                }
              ]
            }
          ]
        }
        """

        let emptyKeysJSON = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": [
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.main",
                  "rows": [
                    {
                      "id": "row.main",
                      "keys": []
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(emptySectionsJSON.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(emptyRowsJSON.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(emptyKeysJSON.utf8)))
    }

    func testDecodedDefinitionRejectsInvalidWidthWeight() {
        let zeroWidthJSON = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": "Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": [
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.main",
                  "rows": [
                    {
                      "id": "row.main",
                      "keys": [
                        {
                          "id": "key.sqrt",
                          "presentation": { "text": { "verbatim": "sqrt" } },
                          "intent": { "semanticToken": { "namespace": "builtin", "name": "sqrt" } },
                          "layoutHint": 0
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let negativeWidthJSON = zeroWidthJSON.replacingOccurrences(of: "\"layoutHint\": 0", with: "\"layoutHint\": -1")

        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(zeroWidthJSON.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(negativeWidthJSON.utf8)))
    }

    func testDecodedDefinitionRejectsInvalidNestedIdentifiers() {
        let invalidIdentifierJSON = """
        {
          "metadata": {
            "id": "builtin.standard",
            "name": " Standard",
            "version": { "major": 1, "minor": 0, "patch": 0 }
          },
          "defaultPageID": "page.main",
          "pages": [
            {
              "id": "page.main",
              "sections": [
                {
                  "id": "section.main",
                  "rows": [
                    {
                      "id": "row.main",
                      "keys": [
                        {
                          "id": "key.sqrt",
                          "presentation": { "text": { "verbatim": "sqrt" } },
                          "intent": { "semanticToken": { "namespace": " builtin", "name": "sqrt" } },
                          "layoutHint": 1
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(FormulaKeyboardDefinition.self, from: Data(invalidIdentifierJSON.utf8)))
    }
}
