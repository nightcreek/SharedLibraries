import Foundation

@MainActor
final class FormulaCursorBlinkController {
    let referenceDate: Date
    let visibleDuration: TimeInterval
    let hiddenDuration: TimeInterval
    let sampleInterval: TimeInterval

    init(
        referenceDate: Date = .now,
        visibleDuration: TimeInterval = 0.6,
        hiddenDuration: TimeInterval = 0.6,
        sampleInterval: TimeInterval = 0.2
    ) {
        self.referenceDate = referenceDate
        self.visibleDuration = visibleDuration
        self.hiddenDuration = hiddenDuration
        self.sampleInterval = sampleInterval
    }

    func isVisible(at date: Date) -> Bool {
        let cycleDuration = max(visibleDuration + hiddenDuration, 0.001)
        let elapsed = max(date.timeIntervalSince(referenceDate), 0)
        let offset = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        return offset < visibleDuration
    }

    func opacity(at date: Date) -> Double {
        isVisible(at: date) ? 1.0 : 0.0
    }
}
