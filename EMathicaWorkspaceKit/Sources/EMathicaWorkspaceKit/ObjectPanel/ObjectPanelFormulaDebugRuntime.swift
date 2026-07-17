#if DEBUG
import EMathicaFormulaDisplayCore
import EMathicaMathCore
import Foundation

public struct FormulaDisplayRuntimeState: Equatable, Sendable {
    public var backend: FormulaRenderingBackend
    public var fontRole: FormulaFontRole

    public init(
        backend: FormulaRenderingBackend,
        fontRole: FormulaFontRole
    ) {
        self.backend = backend
        self.fontRole = fontRole
    }
}

public struct FormulaDisplayDiagnostics: Equatable, Sendable {
    public var swiftMathAttemptCount: Int
    public var swiftMathFallbackCount: Int
    public var legacyFallbackCount: Int
    public var lastFallbackReason: FormulaDisplayFallbackReason?

    public init(
        swiftMathAttemptCount: Int = 0,
        swiftMathFallbackCount: Int = 0,
        legacyFallbackCount: Int = 0,
        lastFallbackReason: FormulaDisplayFallbackReason? = nil
    ) {
        self.swiftMathAttemptCount = swiftMathAttemptCount
        self.swiftMathFallbackCount = swiftMathFallbackCount
        self.legacyFallbackCount = legacyFallbackCount
        self.lastFallbackReason = lastFallbackReason
    }

    public var fallbackCount: Int {
        swiftMathFallbackCount + legacyFallbackCount
    }

    static func make(
        objects: [MathObject],
        selectedObject: MathObject?,
        geometryResolver: any GeometryPresentationResolverProtocol,
        configuration: FormulaRenderingConfiguration
    ) -> FormulaDisplayDiagnostics {
        var diagnostics = FormulaDisplayDiagnostics()
        var sources = objects
            .filter { $0.type != .parameter }
            .map(WorkspaceObjectFormulaSource.make(for:))

        if let selectedObject {
            sources.append(contentsOf: InspectorFormulaSourceBuilder.inspectorSources(for: selectedObject))
        }

        for source in sources {
            measure(source: source, configuration: configuration, into: &diagnostics)
        }

        return diagnostics
    }

    private static func measure(
        source: WorkspaceReadOnlyFormulaSource,
        configuration: FormulaRenderingConfiguration,
        into diagnostics: inout FormulaDisplayDiagnostics
    ) {
        guard !source.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        if configuration.backend == .swiftMath {
            diagnostics.swiftMathAttemptCount += 1
        }

        let resolved: FormulaReadOnlyDisplayResolvedMode
        if let document = source.document {
            resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
                surface: source.surface,
                document: document,
                rawValue: source.rawValue,
                fallbackText: source.fallbackText,
                fontSize: source.fontSize,
                minHeight: source.minHeight,
                allowsMultiline: source.allowsMultiline,
                configuration: configuration
            )
        } else {
            resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
                surface: source.surface,
                rawValue: source.rawValue,
                fallbackText: source.fallbackText,
                fontSize: source.fontSize,
                minHeight: source.minHeight,
                allowsMultiline: source.allowsMultiline,
                configuration: configuration
            )
        }

        switch resolved {
        case .formula(_, _, let options, let fallbackReason):
            guard let fallbackReason else { return }
            diagnostics.lastFallbackReason = fallbackReason
            if configuration.backend == .swiftMath {
                diagnostics.swiftMathFallbackCount += 1
            }
            if options.renderingBackend == .legacy {
                diagnostics.legacyFallbackCount += 1
            }
        case .plainText(_, let fallbackReason):
            diagnostics.lastFallbackReason = fallbackReason
            if configuration.backend == .swiftMath {
                diagnostics.swiftMathFallbackCount += 1
            }
            diagnostics.legacyFallbackCount += 1
        }
    }
}

public typealias ObjectPanelFormulaDisplayRuntimeState = FormulaDisplayRuntimeState
public typealias ObjectPanelFormulaDiagnostics = FormulaDisplayDiagnostics
#endif
