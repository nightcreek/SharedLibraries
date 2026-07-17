import EMathicaFormulaDisplayCore
import SwiftUI

struct FormulaRenderElementView: View {
    let element: FormulaRenderElement
    let style: FormulaDisplayStyle
    let showsCursor: Bool
    let showsDebugFrames: Bool

    var body: some View {
        switch element {
        case .text(let text):
            Text(text.text)
                .font(font(for: text))
                .foregroundStyle(color(for: text))
                .frame(width: max(text.frame.size.width, 1), height: max(text.frame.size.height, 1), alignment: .center)
                .position(
                    x: text.frame.origin.x + text.frame.size.width / 2,
                    y: text.frame.origin.y + text.frame.size.height / 2
                )
        case .line(let line):
            Rectangle()
                .fill(color(for: line))
                .frame(width: max(line.frame.size.width, 0.75), height: max(line.frame.size.height, 0.75))
                .position(
                    x: line.frame.origin.x + line.frame.size.width / 2,
                    y: line.frame.origin.y + line.frame.size.height / 2
                )
        case .radical(let radical):
            Path { path in
                path.move(to: CGPoint(x: radical.checkStart.x, y: radical.checkStart.y))
                path.addLine(to: CGPoint(x: radical.checkBottom.x, y: radical.checkBottom.y))
                path.addLine(to: CGPoint(x: radical.valley.x, y: radical.valley.y))
                path.addLine(to: CGPoint(x: radical.shoulder.x, y: radical.shoulder.y))
                path.addLine(to: CGPoint(x: radical.overlineStart.x, y: radical.overlineStart.y))
                path.addLine(to: CGPoint(x: radical.overlineEnd.x, y: radical.overlineEnd.y))
            }
            .stroke(
                color(for: radical),
                style: StrokeStyle(
                    lineWidth: max(0.82, radical.frame.size.height * 0.024),
                    lineCap: .square,
                    lineJoin: .miter
                )
            )
        case .cursor(let cursor):
            if showsCursor {
                Rectangle()
                    .fill(style.cursorColor)
                    .frame(width: max(cursor.frame.size.width, 1), height: max(cursor.frame.size.height, 1))
                    .position(
                        x: cursor.frame.origin.x + cursor.frame.size.width / 2,
                        y: cursor.frame.origin.y + cursor.frame.size.height / 2
                    )
            }
        case .placeholder(let placeholder):
            RoundedRectangle(cornerRadius: 3)
                .fill(style.placeholderFillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(style.placeholderStrokeColor, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                }
                .frame(width: max(placeholder.frame.size.width, 1), height: max(placeholder.frame.size.height, 1))
                .position(
                    x: placeholder.frame.origin.x + placeholder.frame.size.width / 2,
                    y: placeholder.frame.origin.y + placeholder.frame.size.height / 2
                )
        case .debugFrame(let debugFrame):
            if showsDebugFrames {
                Rectangle()
                    .stroke(style.debugColor, lineWidth: 1)
                    .frame(width: max(debugFrame.frame.size.width, 1), height: max(debugFrame.frame.size.height, 1))
                    .position(
                        x: debugFrame.frame.origin.x + debugFrame.frame.size.width / 2,
                        y: debugFrame.frame.origin.y + debugFrame.frame.size.height / 2
                    )
            }
        }
    }

    private func font(for element: FormulaTextElement) -> Font {
        let estimatedSize = max(element.frame.size.height * 0.72, 8)
        switch element.fontRole {
        case .script:
            return .system(size: estimatedSize * style.scriptScale, weight: .semibold, design: .rounded)
        case .operatorSymbol:
            return .system(size: estimatedSize, weight: .semibold, design: .rounded)
        case .radicalGlyph:
            return .system(size: max(element.frame.size.height * 0.96, 10), weight: .regular, design: .default)
        case .function:
            return .system(size: estimatedSize, weight: .medium, design: .rounded)
        case .raw, .error:
            return .system(size: estimatedSize, weight: .regular, design: .rounded)
        case .normal:
            return .system(size: estimatedSize, weight: .semibold, design: .rounded)
        }
    }

    private func color(for element: FormulaTextElement) -> Color {
        switch element.fontRole {
        case .operatorSymbol:
            return style.operatorColor
        case .radicalGlyph:
            return style.radicalColor
        case .function:
            return style.functionColor
        case .raw:
            return style.rawTextColor
        case .error:
            return style.errorTextColor
        case .normal, .script:
            return style.textColor
        }
    }

    private func color(for element: FormulaLineElement) -> Color {
        switch element.role {
        case .fractionLine:
            return style.fractionLineColor
        case .radical:
            return style.radicalColor
        case .delimiter:
            return style.delimiterColor
        case .cursor:
            return style.cursorColor
        case .debug:
            return style.debugColor
        }
    }

    private func color(for element: FormulaRadicalElement) -> Color {
        switch element.role {
        case .radical:
            return style.radicalColor
        case .debug:
            return style.debugColor
        case .fractionLine:
            return style.fractionLineColor
        case .cursor:
            return style.cursorColor
        case .delimiter:
            return style.delimiterColor
        }
    }
}
