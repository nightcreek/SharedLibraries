import Foundation

public struct ImplicitCurveSampler2D {
    public var evaluator: ExprEvaluator
    public var options: ImplicitCurveSamplingOptions2D

    public init(
        evaluator: ExprEvaluator = .init(),
        options: ImplicitCurveSamplingOptions2D = .defaults(for: .balanced)
    ) {
        self.evaluator = evaluator
        self.options = options
    }

    public func sample(
        relation: Expr,
        xRange: SamplingRange,
        yRange: SamplingRange,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        var issues: [SamplingIssue] = []
        var issueKindsSeen: Set<SamplingIssueKind> = []

        func appendIssue(kind: SamplingIssueKind, message: String) {
            guard !issueKindsSeen.contains(kind) else { return }
            issueKindsSeen.insert(kind)
            issues.append(.init(kind: kind, message: message))
        }

        guard xRange.lower < xRange.upper else {
            appendIssue(kind: .invalidRange, message: "xRange.lower must be < xRange.upper")
            return .init(segments: [], issues: issues)
        }
        guard yRange.lower < yRange.upper else {
            appendIssue(kind: .invalidRange, message: "yRange.lower must be < yRange.upper")
            return .init(segments: [], issues: issues)
        }
        guard options.xResolution >= 2, options.yResolution >= 2 else {
            appendIssue(kind: .insufficientSamples, message: "xResolution and yResolution must be >= 2")
            return .init(segments: [], issues: issues)
        }

        guard let field = scalarField(from: relation) else {
            appendIssue(kind: .unsupportedIntent, message: "ImplicitCurveSampler2D currently supports only equality relations.")
            return .init(segments: [], issues: issues)
        }

        let xStep = (xRange.upper - xRange.lower) / Double(options.xResolution - 1)
        let yStep = (yRange.upper - yRange.lower) / Double(options.yResolution - 1)
        let xs = (0..<options.xResolution).map { xRange.lower + Double($0) * xStep }
        let ys = (0..<options.yResolution).map { yRange.lower + Double($0) * yStep }

        var grid = Array(
            repeating: Array<Double?>(repeating: nil, count: options.yResolution),
            count: options.xResolution
        )

        for xi in 0..<options.xResolution {
            for yi in 0..<options.yResolution {
                var envValues = environment.values
                envValues[Symbol(name: "x", role: .variable)] = xs[xi]
                envValues[Symbol(name: "y", role: .variable)] = ys[yi]
                let env = EvaluationEnvironment(values: envValues)
                let result = evaluator.evaluate(field, environment: env)
                switch result {
                case .value(let value):
                    guard value.isFinite else {
                        appendIssue(kind: .nonFinitePoint, message: "non-finite implicit field value on grid")
                        continue
                    }
                    guard abs(xs[xi]) <= options.maxAbsCoordinate, abs(ys[yi]) <= options.maxAbsCoordinate, abs(value) <= options.maxAbsCoordinate else {
                        appendIssue(kind: .nonFinitePoint, message: "implicit field point/value exceeds maxAbsCoordinate")
                        continue
                    }
                    grid[xi][yi] = value
                case .undefined:
                    appendIssue(kind: .evaluationUndefined, message: "implicit field evaluation undefined on grid")
                }
            }
        }

        var rawSegments: [SampleSegment2D] = []

        // Corner order:
        // 0: bottomLeft, 1: bottomRight, 2: topRight, 3: topLeft
        // Edge order:
        // bottom(0->1), right(1->2), top(3->2), left(0->3)
        for xi in 0..<(options.xResolution - 1) {
            for yi in 0..<(options.yResolution - 1) {
                guard let bl = grid[xi][yi],
                      let br = grid[xi + 1][yi],
                      let tr = grid[xi + 1][yi + 1],
                      let tl = grid[xi][yi + 1] else {
                    continue
                }

                let pBL = SamplePoint2D(x: xs[xi], y: ys[yi])
                let pBR = SamplePoint2D(x: xs[xi + 1], y: ys[yi])
                let pTR = SamplePoint2D(x: xs[xi + 1], y: ys[yi + 1])
                let pTL = SamplePoint2D(x: xs[xi], y: ys[yi + 1])

                let caseIndex =
                    (bl > 0 ? 1 : 0) |
                    (br > 0 ? 2 : 0) |
                    (tr > 0 ? 4 : 0) |
                    (tl > 0 ? 8 : 0)

                var edgePoints: [(edge: Int, point: SamplePoint2D)] = []
                if let point = interpolateEdge(p1: pBL, v1: bl, p2: pBR, v2: br) {
                    edgePoints.append((edge: 0, point: point))
                }
                if let point = interpolateEdge(p1: pBR, v1: br, p2: pTR, v2: tr) {
                    edgePoints.append((edge: 1, point: point))
                }
                if let point = interpolateEdge(p1: pTL, v1: tl, p2: pTR, v2: tr) {
                    edgePoints.append((edge: 2, point: point))
                }
                if let point = interpolateEdge(p1: pBL, v1: bl, p2: pTL, v2: tl) {
                    edgePoints.append((edge: 3, point: point))
                }

                if edgePoints.count == 2 {
                    rawSegments.append(.init(points: [edgePoints[0].point, edgePoints[1].point]))
                } else if edgePoints.count == 4 {
                    // Ambiguous cases (typically 5/10): emit two independent segments in this cell.
                    let edgeToPoint = Dictionary(uniqueKeysWithValues: edgePoints.map { ($0.edge, $0.point) })
                    if caseIndex == 5 {
                        if let b = edgeToPoint[0], let l = edgeToPoint[3] {
                            rawSegments.append(.init(points: [b, l]))
                        }
                        if let r = edgeToPoint[1], let t = edgeToPoint[2] {
                            rawSegments.append(.init(points: [r, t]))
                        }
                    } else if caseIndex == 10 {
                        if let b = edgeToPoint[0], let r = edgeToPoint[1] {
                            rawSegments.append(.init(points: [b, r]))
                        }
                        if let l = edgeToPoint[3], let t = edgeToPoint[2] {
                            rawSegments.append(.init(points: [l, t]))
                        }
                    } else {
                        // Fallback pairing by traversal order.
                        rawSegments.append(.init(points: [edgePoints[0].point, edgePoints[1].point]))
                        rawSegments.append(.init(points: [edgePoints[2].point, edgePoints[3].point]))
                    }
                }
            }
        }

        let segments: [SampleSegment2D]
        if options.enableSegmentStitching {
            let stitcher = SegmentStitcher2D(tolerance: options.stitchingTolerance)
            segments = stitcher.stitch(rawSegments)
        } else {
            segments = rawSegments
        }

        return .init(segments: segments, issues: issues)
    }

    private func scalarField(from relation: Expr) -> Expr? {
        switch relation {
        case .equation(let left, let right):
            return .add([left, .negate(right)])
        case .relation(let left, let op, let right) where op == .equal:
            return .add([left, .negate(right)])
        default:
            return nil
        }
    }

    private func interpolateEdge(
        p1: SamplePoint2D,
        v1: Double,
        p2: SamplePoint2D,
        v2: Double
    ) -> SamplePoint2D? {
        if v1 == 0, v2 == 0 { return nil }
        if !(v1 == 0 || v2 == 0 || (v1 < 0) != (v2 < 0)) { return nil }

        let denom = v1 - v2
        if abs(denom) < .ulpOfOne { return nil }
        let t = v1 / denom
        if !t.isFinite { return nil }

        let x = p1.x + t * (p2.x - p1.x)
        let y = p1.y + t * (p2.y - p1.y)
        guard x.isFinite, y.isFinite else { return nil }
        return .init(x: x, y: y)
    }
}
