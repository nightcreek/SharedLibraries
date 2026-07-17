import Foundation

public enum FormulaDisplayFallbackReason: String, Sendable, Equatable {
    case parserError
    case unsupportedCommand
    case resourceFailure
    case emptyOutput
    case invalidIntrinsicSize
}

public struct FormulaReadOnlyRenderMeasurement: Sendable, Equatable {
    public var width: Double
    public var height: Double
    public var baseline: Double

    public init(width: Double, height: Double, baseline: Double) {
        self.width = width
        self.height = height
        self.baseline = baseline
    }
}

public enum FormulaReadOnlyRenderProbeResult: Sendable, Equatable {
    case success(FormulaReadOnlyRenderMeasurement)
    case failure(FormulaDisplayFallbackReason, message: String)
}

public enum FormulaReadOnlyRenderProbe {
    public static func measure(
        markup: FormulaDisplayMarkup,
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default
    ) -> FormulaReadOnlyRenderProbeResult {
        let trimmed = markup.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.emptyOutput, message: "Formula markup is empty.")
        }

        switch options.renderingBackend {
        case .legacy:
            let plan = FormulaDisplayEngine(options: options, metrics: metrics).getPlan(from: markup)
            let width = Double(plan.bounds.size.width)
            let height = Double(plan.bounds.size.height)
            let baseline = Double(plan.baseline)
            guard width.isFinite, height.isFinite, baseline.isFinite, width > 0, height > 0 else {
                return .failure(.invalidIntrinsicSize, message: "Legacy formula renderer produced an invalid size.")
            }
            return .success(.init(width: width, height: height, baseline: baseline))
        case .swiftMath:
            let resolved = FormulaDisplayContentResolver.resolve(
                markup: markup,
                options: options,
                metrics: metrics,
                foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
            )
            switch resolved {
            case .swiftMath(let snapshot):
                let width = snapshot.size.width
                let height = snapshot.size.height
                let baseline = snapshot.baseline
                guard width.isFinite, height.isFinite, baseline.isFinite, width > 0, height > 0 else {
                    return .failure(.invalidIntrinsicSize, message: "SwiftMath produced an invalid intrinsic size.")
                }
                return .success(.init(width: width, height: height, baseline: baseline))
            case .swiftMathError(let error):
                return .failure(mapFallbackReason(error), message: error.message)
            case .legacy(let plan):
                let width = Double(plan.bounds.size.width)
                let height = Double(plan.bounds.size.height)
                let baseline = Double(plan.baseline)
                guard width.isFinite, height.isFinite, baseline.isFinite, width > 0, height > 0 else {
                    return .failure(.invalidIntrinsicSize, message: "Legacy formula renderer produced an invalid size.")
                }
                return .success(.init(width: width, height: height, baseline: baseline))
            }
        }
    }

    private static func mapFallbackReason(_ error: FormulaSwiftMathRenderError) -> FormulaDisplayFallbackReason {
        let lowered = error.message.lowercased()
        if error.code == 1000 || lowered.contains("empty") || lowered.contains("non-empty") {
            return .emptyOutput
        }
        if error.domain == "ParseError" {
            switch error.code {
            case 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14:
                return .parserError
            case 2:
                return .unsupportedCommand
            default:
                return .resourceFailure
            }
        }
        if lowered.contains("mathscr") || lowered.contains("unsupported") || lowered.contains("unknown command") {
            return .unsupportedCommand
        }
        if lowered.contains("parse") || lowered.contains("brace") || lowered.contains("matrix") || lowered.contains("environment") {
            return .parserError
        }
        if lowered.contains("size") || lowered.contains("output") {
            return .invalidIntrinsicSize
        }
        return .resourceFailure
    }
}
