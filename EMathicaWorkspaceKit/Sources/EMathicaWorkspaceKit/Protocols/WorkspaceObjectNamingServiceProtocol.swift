import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

public protocol WorkspaceObjectNamingServiceProtocol {
    func preferredFunctionName(from relation: AlgebraRelation?) -> String?
    func nextFunctionName(existingObjects: [MathObject]) -> String
    func nextParameterName(existingObjects: [MathObject]) -> String
    func nextPointName(existingObjects: [MathObject]) -> String
    func nextPointNames(existingObjects: [MathObject], count: Int) -> [String]
    func nextSegmentName(existingObjects: [MathObject]) -> String
    func nextLineName(existingObjects: [MathObject]) -> String
    func nextRayName(existingObjects: [MathObject]) -> String
    func nextCircleName(existingObjects: [MathObject]) -> String
    func nextArcName(existingObjects: [MathObject]) -> String
}

public struct DefaultWorkspaceObjectNamingService: WorkspaceObjectNamingServiceProtocol {
    public init() {}
}

public extension WorkspaceModuleProviding {
    var objectNamingService: (any WorkspaceObjectNamingServiceProtocol)? { nil }
}

public extension WorkspaceObjectNamingServiceProtocol {
    func preferredFunctionName(from relation: AlgebraRelation?) -> String? {
        guard let relation else { return nil }
        guard case .equation(let equation) = relation else { return nil }
        if case .function(let name, _) = equation.left, isUserFunctionName(name) {
            return name
        }
        if case .function(let name, _) = equation.right, isUserFunctionName(name) {
            return name
        }
        return nil
    }

    func resolvedExplicitFunctionName(
        from relation: AlgebraRelation?,
        existingObjects: [MathObject],
        excluding excludedObjectID: UUID? = nil
    ) -> String? {
        guard let name = preferredFunctionName(from: relation) else { return nil }
        return resolvedExplicitFunctionName(
            name,
            existingObjects: existingObjects,
            excluding: excludedObjectID
        )
    }

    func resolvedExplicitFunctionName(
        _ proposedName: String,
        existingObjects: [MathObject],
        excluding excludedObjectID: UUID? = nil
    ) -> String {
        let usedNames = Set(
            existingObjects
                .filter { $0.type == .function && $0.id != excludedObjectID }
                .map(\.name)
        )
        guard usedNames.contains(proposedName) else { return proposedName }

        var suffix = 1
        while usedNames.contains("\(proposedName)_\(suffix)") {
            suffix += 1
        }
        return "\(proposedName)_\(suffix)"
    }

    func nextFunctionName(existingObjects: [MathObject]) -> String {
        nextNumberedName(
            prefix: "f_",
            type: .function,
            existingObjects: existingObjects,
            shouldIgnore: isDerivativeLikeFunction
        )
    }

    func nextParameterName(existingObjects: [MathObject]) -> String {
        let used = Set(existingObjects.filter { $0.type == .parameter }.map(\.name))
        let candidates = ["a", "b", "c", "n", "r", "k", "m"]
        if let candidate = candidates.first(where: { !used.contains($0) }) {
            return candidate
        }

        var index = 1
        while used.contains("p\(index)") {
            index += 1
        }
        return "p\(index)"
    }

    func nextPointName(existingObjects: [MathObject]) -> String {
        let used = Set(existingObjects.filter { $0.type == .point }.map(\.name))
        return nextPointName(usedNames: used)
    }

    func nextPointNames(existingObjects: [MathObject], count: Int) -> [String] {
        guard count > 0 else { return [] }
        var used = Set(existingObjects.filter { $0.type == .point }.map(\.name))
        var result: [String] = []
        result.reserveCapacity(count)

        for _ in 0..<count {
            let name = nextPointName(usedNames: used)
            result.append(name)
            used.insert(name)
        }
        return result
    }

    func nextSegmentName(existingObjects: [MathObject]) -> String {
        nextNumberedName(prefix: "s_", type: .segment, existingObjects: existingObjects)
    }

    func nextLineName(existingObjects: [MathObject]) -> String {
        nextNumberedName(prefix: "ℓ", type: .line, existingObjects: existingObjects)
    }

    func nextRayName(existingObjects: [MathObject]) -> String {
        nextNumberedName(prefix: "r", type: .ray, existingObjects: existingObjects)
    }

    func nextCircleName(existingObjects: [MathObject]) -> String {
        nextNumberedName(prefix: "c", type: .circle, existingObjects: existingObjects)
    }

    func nextArcName(existingObjects: [MathObject]) -> String {
        nextNumberedName(prefix: "a", type: .arc, existingObjects: existingObjects)
    }

    private func nextPointName(usedNames: Set<String>) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
        var suffix = 0
        while true {
            for letter in letters {
                let candidate = suffix == 0 ? letter : "\(letter)_\(suffix)"
                if !usedNames.contains(candidate) {
                    return candidate
                }
            }
            suffix += 1
        }
    }

    private func nextNumberedName(
        prefix: String,
        type: MathObjectType,
        existingObjects: [MathObject],
        shouldIgnore: (MathObject) -> Bool = { _ in false }
    ) -> String {
        let used = Set(
            existingObjects
                .filter { $0.type == type && !shouldIgnore($0) }
                .compactMap { object in
                    parsedIndex(from: object.name, prefix: prefix)
                }
        )
        var index = 1
        while used.contains(index) {
            index += 1
        }
        return "\(prefix)\(index)"
    }

    private func parsedIndex(from name: String, prefix: String) -> Int? {
        guard name.hasPrefix(prefix) else { return nil }
        let suffix = String(name.dropFirst(prefix.count))
        guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber), let value = Int(suffix), value > 0 else {
            return nil
        }
        return value
    }

    private func isDerivativeLikeFunction(_ object: MathObject) -> Bool {
        let name = object.name
        return name.contains("'") || name.contains("^(")
    }

    private func isUserFunctionName(_ name: String) -> Bool {
        !["sin", "cos", "tan", "sqrt", "abs", "log", "ln", "exp"].contains(name)
    }
}
