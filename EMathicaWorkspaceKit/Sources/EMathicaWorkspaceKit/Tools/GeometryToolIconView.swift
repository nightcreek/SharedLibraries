import SwiftUI

public struct GeometryToolIconView: View {
    public let glyph: GeometryToolGlyph

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let stroke = max(1.25, min(w, h) * 0.085)

            ZStack {
                switch glyph {
                case .point:
                    Circle()
                        .fill(Color.primary)
                        .frame(width: w * 0.22, height: h * 0.22)

                case .segment:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.2, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.28))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    endpoint(x: w * 0.2, y: h * 0.72, radius: w * 0.08)
                    endpoint(x: w * 0.8, y: h * 0.28, radius: w * 0.08)

                case .midpoint:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.16, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.28))
                    }
                    .stroke(Color.primary.opacity(0.85), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    endpoint(x: w * 0.16, y: h * 0.72, radius: w * 0.07)
                    endpoint(x: w * 0.84, y: h * 0.28, radius: w * 0.07)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: w * 0.18, height: h * 0.18)
                        .position(x: w * 0.5, y: h * 0.5)

                case .line:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.06, y: h * 0.78))
                        path.addLine(to: CGPoint(x: w * 0.94, y: h * 0.22))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    endpointStroke(x: w * 0.28, y: h * 0.64, radius: w * 0.055, stroke: stroke * 0.75)
                    endpointStroke(x: w * 0.72, y: h * 0.36, radius: w * 0.055, stroke: stroke * 0.75)

                case .ray:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.2, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.3))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    endpoint(x: w * 0.2, y: h * 0.72, radius: w * 0.075)
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.76, y: h * 0.26))
                        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.24))
                        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.36))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))

                case .parallel:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.18, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.74, y: h * 0.38))
                    }
                    .stroke(Color.primary.opacity(0.75), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.28, y: h * 0.84))
                        path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.5))
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: stroke, lineCap: .round))

                case .perpendicular:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.12, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.72))
                    }
                    .stroke(Color.primary.opacity(0.78), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.52, y: h * 0.92))
                        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.2))
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.52, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.66, y: h * 0.72))
                        path.addLine(to: CGPoint(x: w * 0.66, y: h * 0.58))
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: stroke * 0.8, lineCap: .round, lineJoin: .round))

                case .circle:
                    Circle()
                        .stroke(Color.primary, lineWidth: stroke)
                        .frame(width: w * 0.66, height: h * 0.66)
                        .position(x: w * 0.52, y: h * 0.52)
                    endpoint(x: w * 0.52, y: h * 0.52, radius: w * 0.06)
                    endpoint(x: w * 0.78, y: h * 0.52, radius: w * 0.055)

                case .arc:
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: w * 0.50, y: h * 0.62),
                            radius: w * 0.30,
                            startAngle: .degrees(160),
                            endAngle: .degrees(20),
                            clockwise: true
                        )
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    endpoint(x: w * 0.22, y: h * 0.52, radius: w * 0.06)
                    endpoint(x: w * 0.78, y: h * 0.52, radius: w * 0.06)

                case .intersection:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.14, y: h * 0.82))
                        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.2))
                    }
                    .stroke(Color.primary.opacity(0.82), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.14, y: h * 0.2))
                        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.82))
                    }
                    .stroke(Color.primary.opacity(0.82), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: w * 0.18, height: h * 0.18)
                        .position(x: w * 0.5, y: h * 0.5)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func endpoint(x: CGFloat, y: CGFloat, radius: CGFloat) -> some View {
        Circle()
            .fill(Color.primary)
            .frame(width: radius * 2, height: radius * 2)
            .position(x: x, y: y)
    }

    @ViewBuilder
    private func endpointStroke(x: CGFloat, y: CGFloat, radius: CGFloat, stroke: CGFloat) -> some View {
        Circle()
            .stroke(Color.primary, lineWidth: stroke)
            .frame(width: radius * 2, height: radius * 2)
            .position(x: x, y: y)
    }
}
