import EMathicaFormulaDisplayCore
import Foundation

struct FormulaInsertionHitResolver {
    static func resolve(
        at point: CGPoint,
        layout: FormulaEditorCanvasLayout,
        insertionAnchors: [FormulaInsertionAnchor],
        placeholderAnchors: [FormulaPlaceholderAnchor]
    ) -> FormulaInsertionID? {
        let insertionCandidates = insertionAnchors.map {
            InsertionCandidate(anchor: $0, canvasRect: canvasRect(for: $0, in: layout))
        }

        if let placeholderCandidate = bestPlaceholderHit(
            at: point,
            layout: layout,
            placeholderAnchors: placeholderAnchors,
            insertionCandidates: insertionCandidates
        ) {
            return placeholderCandidate.anchor.id
        }

        return bestInsertionCandidate(
            at: point,
            insertionCandidates: insertionCandidates
        )?.anchor.id
    }

    private static func bestPlaceholderHit(
        at point: CGPoint,
        layout: FormulaEditorCanvasLayout,
        placeholderAnchors: [FormulaPlaceholderAnchor],
        insertionCandidates: [InsertionCandidate]
    ) -> InsertionCandidate? {
        let hitPlaceholders = zip(placeholderAnchors, layout.placeholderRects)
            .filter { pair in
                pair.1.insetBy(dx: -2, dy: -2).contains(point)
            }
            .map { $0.0 }

        guard let placeholder = hitPlaceholders.min(by: placeholderComparator(_:_:)) else {
            return nil
        }

        let matching = insertionCandidates.filter {
            $0.anchor.sourcePath == placeholder.sourcePath &&
            $0.anchor.fieldIdentity == placeholder.fieldIdentity
        }
        if let best = bestInsertionCandidate(
            at: point,
            insertionCandidates: matching.isEmpty ? insertionCandidates : matching
        ) {
            return best
        }

        return insertionCandidates.first(where: {
            $0.anchor.sourcePath == placeholder.sourcePath &&
            $0.anchor.fieldIdentity == placeholder.fieldIdentity
        })
    }

    private static func placeholderComparator(
        _ lhs: FormulaPlaceholderAnchor,
        _ rhs: FormulaPlaceholderAnchor
    ) -> Bool {
        let lhsArea = lhs.rect.size.width * lhs.rect.size.height
        let rhsArea = rhs.rect.size.width * rhs.rect.size.height
        if lhsArea != rhsArea {
            return lhsArea < rhsArea
        }
        if lhs.sourcePath != rhs.sourcePath {
            return lhs.sourcePath.lexicographicallyPrecedes(rhs.sourcePath)
        }
        return (lhs.fieldIdentity ?? "") < (rhs.fieldIdentity ?? "")
    }

    private static func bestInsertionCandidate(
        at point: CGPoint,
        insertionCandidates: [InsertionCandidate]
    ) -> InsertionCandidate? {
        insertionCandidates.min { lhs, rhs in
            candidateScore(point: point, candidate: lhs) < candidateScore(point: point, candidate: rhs)
        }
    }

    private static func candidateScore(point: CGPoint, candidate: InsertionCandidate) -> Double {
        let rect = candidate.canvasRect
        let dx = max(0, abs(point.x - rect.midX) - rect.width / 2)
        let dy = max(0, abs(point.y - rect.midY) - rect.height / 2)
        var score = dx * 1.5 + dy * 3.5

        if rect.contains(point) {
            score -= 100
        }
        if candidate.anchor.sourcePath.isEmpty {
            score -= 0.25
        }
        if candidate.anchor.fieldIdentity != nil {
            score -= 0.5
        }
        return score
    }

    private static func canvasRect(
        for anchor: FormulaInsertionAnchor,
        in layout: FormulaEditorCanvasLayout
    ) -> CGRect {
        CGRect(
            origin: CGPoint(
                x: anchor.rect.origin.x + layout.contentOrigin.x,
                y: anchor.rect.origin.y + layout.contentOrigin.y
            ),
            size: CGSize(
                width: anchor.rect.size.width,
                height: anchor.rect.size.height
            )
        )
    }

    private struct InsertionCandidate {
        let anchor: FormulaInsertionAnchor
        let canvasRect: CGRect
    }
}
