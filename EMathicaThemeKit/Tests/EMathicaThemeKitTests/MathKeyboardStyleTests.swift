import XCTest
@testable import EMathicaThemeKit

final class MathKeyboardStyleTests: XCTestCase {
    func testDefaultStyleExistsWithValidRanges() {
        let style = MathKeyboardStyle.default

        XCTAssertGreaterThan(style.panel.cornerRadius, 0)
        XCTAssertGreaterThan(style.key.cornerRadius, 0)
        XCTAssertGreaterThan(style.tab.cornerRadius, 0)

        XCTAssertGreaterThan(style.spacing.shellPadding, 0)
        XCTAssertGreaterThan(style.spacing.rowSpacing, 0)
        XCTAssertGreaterThan(style.spacing.keySpacing, 0)
        XCTAssertGreaterThan(style.spacing.keyMinHeight, 0)

        XCTAssertGreaterThan(style.typography.primaryFontSize, 0)
        XCTAssertGreaterThan(style.typography.templatePrimaryFontSize, 0)
        XCTAssertGreaterThan(style.typography.secondaryFontSize, 0)
        XCTAssertGreaterThan(style.typography.tabFontSize, 0)

        assertUnit(style.panel.shellBackgroundDarkOpacity)
        assertUnit(style.panel.shellBackgroundLightOpacity)
        assertUnit(style.panel.backplateBackgroundDarkOpacity)
        assertUnit(style.panel.backplateBackgroundLightOpacity)
        assertUnit(style.key.normalBackgroundDarkOpacity)
        assertUnit(style.key.normalBackgroundLightOpacity)
        assertUnit(style.tab.selectedBackgroundOpacity)
        assertUnit(style.tab.unselectedBackgroundOpacity)
    }

    func testStyleIsEquatableAndCustomizable() {
        let baseline = MathKeyboardStyle.default
        var customized = baseline
        customized.spacing.rowSpacing = 9
        customized.typography.primaryFontSize = 16

        XCTAssertEqual(baseline, .default)
        XCTAssertNotEqual(baseline, customized)
        XCTAssertEqual(customized.spacing.rowSpacing, 9)
        XCTAssertEqual(customized.typography.primaryFontSize, 16)
    }

    private func assertUnit(_ value: Double, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(value, 0, file: file, line: line)
        XCTAssertLessThanOrEqual(value, 1, file: file, line: line)
    }
}
