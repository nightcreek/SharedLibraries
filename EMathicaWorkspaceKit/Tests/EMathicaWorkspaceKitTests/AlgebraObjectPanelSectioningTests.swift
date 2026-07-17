import XCTest
import EMathicaMathCore
@testable import EMathicaWorkspaceKit

final class AlgebraObjectPanelSectioningTests: XCTestCase {
    func testSectionsGroupObjectsByPlaneFacingBuckets() {
        let point = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            style: MathStyle(colorToken: "blue")
        )
        let function = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=x^2"),
            style: MathStyle(colorToken: "pink")
        )
        let slider = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=1"),
            parameterValue: 1,
            style: MathStyle(colorToken: "indigo")
        )

        let sections = AlgebraObjectPanelSection.makeSections(from: [point, function, slider])

        XCTAssertEqual(sections.map(\.kind), [.parameters, .functionsAndCurves, .geometry])
        XCTAssertEqual(sections.map { $0.objects.count }, [1, 1, 1])
    }

    func testContentHeightAddsSectionChromeForMixedGroups() {
        let slider = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=2"),
            parameterValue: 2,
            style: MathStyle(colorToken: "indigo")
        )
        let function = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=sin(x)+a"),
            style: MathStyle(colorToken: "green")
        )

        let height = AlgebraObjectPanelLayoutMetrics.contentHeight(for: [slider, function])
        let expected = AlgebraObjectPanelLayoutMetrics.panelVerticalPadding
            + AlgebraObjectPanelLayoutMetrics.headerHeight
            + AlgebraObjectPanelLayoutMetrics.headerToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderHeight
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.sliderRowHeight
            + AlgebraObjectPanelLayoutMetrics.sectionSpacing
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderHeight
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.normalRowHeight

        XCTAssertEqual(height, expected)
    }

    func testObjectNameMarkupFormatsSubscriptedFunctionName() {
        XCTAssertEqual(
            WorkspaceFormulaMarkupResolver.nameMarkup(for: "f_1"),
            "f_{1}"
        )
        XCTAssertEqual(
            WorkspaceFormulaMarkupResolver.nameMarkup(for: "A"),
            "A"
        )
    }

    func testObjectExpressionMarkupPrefersStructuredDisplayBeforeOriginalLatexFallback() {
        XCTAssertEqual(
            WorkspaceFormulaMarkupResolver.expressionMarkup(
                displayText: "y=x^2",
                originalLatex: "y=x^{2}",
                rawInput: "y=x^2"
            ),
            "y=x^2"
        )
        XCTAssertEqual(
            WorkspaceFormulaMarkupResolver.expressionMarkup(
                displayText: "y=x^2",
                originalLatex: nil,
                rawInput: "y=x^2"
            ),
            "y=x^2"
        )
        XCTAssertEqual(
            WorkspaceFormulaMarkupResolver.expressionMarkup(
                displayText: "x(t)=t\ny(t)=t",
                originalLatex: nil,
                rawInput: "\\parametric{t}{t}{t>0}"
            ),
            "\\parametric{t}{t}{t>0}"
        )
    }

    func testObjectRowFormulaDisplayUsesCompactSpacingPolicy() {
        XCTAssertEqual(WorkspaceObjectFormulaDisplayMetrics.nameMaxWidth, 44)
        XCTAssertEqual(WorkspaceObjectFormulaDisplayMetrics.nameToExpressionSpacing, 1)
        XCTAssertEqual(WorkspaceObjectFormulaDisplayMetrics.colonTrailingSpacing, 1)
        XCTAssertTrue(WorkspaceObjectFormulaDisplayMetrics.singleLineUsesHorizontalScroll)
    }
}
