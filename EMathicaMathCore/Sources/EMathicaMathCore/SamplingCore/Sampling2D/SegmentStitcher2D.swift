public struct SegmentStitcher2D {
    public var tolerance: Double

    public init(tolerance: Double = 1e-8) {
        self.tolerance = tolerance
    }

    public func stitch(
        _ segments: [SampleSegment2D]
    ) -> [SampleSegment2D] {
        var stitched: [SampleSegment2D] = []
        var used = Array(repeating: false, count: segments.count)

        for index in segments.indices {
            if used[index] { continue }
            used[index] = true
            var chain = segments[index].points
            if chain.isEmpty {
                stitched.append(segments[index])
                continue
            }

            var progressed = true
            while progressed {
                progressed = false

                for candidateIndex in segments.indices where !used[candidateIndex] {
                    let candidate = segments[candidateIndex]
                    guard !candidate.points.isEmpty else {
                        used[candidateIndex] = true
                        progressed = true
                        continue
                    }

                    if tryMerge(chain: &chain, with: candidate.points) {
                        used[candidateIndex] = true
                        progressed = true
                    }
                }
            }

            stitched.append(.init(points: chain))
        }

        return stitched
    }

    private func tryMerge(
        chain: inout [SamplePoint2D],
        with candidate: [SamplePoint2D]
    ) -> Bool {
        guard let chainFirst = chain.first, let chainLast = chain.last else { return false }
        guard let candidateFirst = candidate.first, let candidateLast = candidate.last else { return false }

        if near(chainLast, candidateFirst) {
            chain.append(contentsOf: candidate.dropFirst())
            return true
        }
        if near(chainLast, candidateLast) {
            chain.append(contentsOf: candidate.reversed().dropFirst())
            return true
        }
        if near(chainFirst, candidateLast) {
            chain.insert(contentsOf: candidate.dropLast(), at: 0)
            return true
        }
        if near(chainFirst, candidateFirst) {
            chain.insert(contentsOf: candidate.reversed().dropLast(), at: 0)
            return true
        }

        return false
    }

    private func near(_ a: SamplePoint2D, _ b: SamplePoint2D) -> Bool {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return dx * dx + dy * dy <= tolerance * tolerance
    }
}
