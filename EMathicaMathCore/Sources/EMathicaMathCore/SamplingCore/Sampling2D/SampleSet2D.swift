public struct SampleSet2D: Equatable, Sendable {
    public var segments: [SampleSegment2D]
    public var issues: [SamplingIssue]

    public init(segments: [SampleSegment2D], issues: [SamplingIssue]) {
        self.segments = segments
        self.issues = issues
    }

    public func mapPoints(
        _ transform: (SamplePoint2D) -> SamplePoint2D
    ) -> SampleSet2D {
        let mappedSegments = segments.map { segment in
            SampleSegment2D(points: segment.points.map(transform))
        }
        return SampleSet2D(segments: mappedSegments, issues: issues)
    }
}
