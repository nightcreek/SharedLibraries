import EMathicaMathInputCore
import Foundation
import EMathicaMathCore

public struct MathNodeSemanticLowering {
    public init() {}
    public func lower(_ root: MathNode, context: LoweringContext = .init()) -> LoweringResult {
        var diagnostics: [ExprDiagnostic] = []
        var sourceMap: [ExprPath: ExprSourceLocation] = [:]
        let lowered = lowerNode(root, path: ExprPath(), context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)

        let hasError = diagnostics.contains { $0.severity == .error }
        let expr = hasError ? nil : lowered
        return LoweringResult(
            expr: expr,
            diagnostics: diagnostics,
            sourceMap: sourceMap,
            succeeded: expr != nil
        )
    }

    private func lowerNode(
        _ node: MathNode,
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> Expr? {
        switch node {
        case .placeholder:
            emit(.error, .unresolvedPlaceholder, "表达式包含未完成占位符", path: path, diagnostics: &diagnostics)
            return nil
        case .character(let value):
            return lowerLooseToken(value, path: path, diagnostics: &diagnostics)
        case .symbol(let value):
            if let constant = resolveNamedConstant(value) {
                return constant
            }
            return .symbol(Symbol(name: value, role: .unknown))
        case .operatorSymbol(let value):
            emit(.error, .missingOperand, "孤立运算符: \(value)", path: path, diagnostics: &diagnostics)
            return nil
        case .sequence(let nodes):
            return lowerSequence(nodes, path: path, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)
        case .template(let template):
            return lowerTemplate(template, path: path, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)
        }
    }

    private func lowerLooseToken(
        _ value: String,
        path: ExprPath,
        diagnostics: inout [ExprDiagnostic]
    ) -> Expr? {
        let trimmed = MathInputCharacterNormalizer.normalize(value).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            emit(.error, .emptyExpression, "空表达式", path: path, diagnostics: &diagnostics)
            return nil
        }
        if let number = parseNumericLiteral(trimmed, path: path, diagnostics: &diagnostics) {
            return number
        }
        if let constant = resolveNamedConstant(trimmed) {
            return constant
        }
        return .symbol(Symbol(name: trimmed, role: .unknown))
    }

    private func lowerTemplate(
        _ template: TemplateNode,
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> Expr? {
        func fieldExpr(_ id: FieldID) -> Expr? {
            let fieldPath = path.appending(.field(fieldName(id)))
            guard let node = template.field(id) else {
                emit(.error, .missingArgument, "模板字段缺失: \(fieldName(id))", path: fieldPath, diagnostics: &diagnostics)
                return nil
            }
            return lowerNode(node, path: fieldPath, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)
        }

        switch template.kind {
        case .fraction:
            guard let n = fieldExpr(.numerator), let d = fieldExpr(.denominator) else { return nil }
            return .divide(numerator: n, denominator: d)
        case .sqrt:
            guard let arg = fieldExpr(.radicand) else { return nil }
            return .function(.sqrt, arguments: [arg])
        case .nthRoot:
            guard let degree = fieldExpr(.rootIndex), let arg = fieldExpr(.radicand) else { return nil }
            return .function(.custom("root"), arguments: [degree, arg])
        case .superscript:
            guard let base = fieldExpr(.base), let exp = fieldExpr(.exponent) else { return nil }
            return .power(base: base, exponent: exp)
        case .subscriptTemplate:
            guard let base = fieldExpr(.base), let sub = fieldExpr(.subscriptField) else { return nil }
            if case .symbol(let baseSymbol) = base, case .symbol(let subSymbol) = sub {
                return .symbol(Symbol(name: "\(baseSymbol.name)_\(subSymbol.name)", role: baseSymbol.role, namespace: baseSymbol.namespace))
            }
            emit(.warning, .unsupportedExpression, "当前版本未完整支持下标语义，已降级为 unknown", path: path, diagnostics: &diagnostics)
            return .unknown("subscript")
        case .subscriptSuperscript:
            guard let base = fieldExpr(.base), let sub = fieldExpr(.subscriptField), let exp = fieldExpr(.exponent) else { return nil }
            let withSub: Expr
            if case .symbol(let baseSymbol) = base, case .symbol(let subSymbol) = sub {
                withSub = .symbol(Symbol(name: "\(baseSymbol.name)_\(subSymbol.name)", role: baseSymbol.role, namespace: baseSymbol.namespace))
            } else {
                withSub = .unknown("subscript")
                emit(.warning, .unsupportedExpression, "下标底数不是简单符号，已降级处理", path: path, diagnostics: &diagnostics)
            }
            return .power(base: withSub, exponent: exp)
        case .parentheses, .brackets, .braces:
            guard let content = fieldExpr(.content) else { return nil }
            return content
        case .absoluteValue:
            guard let arg = fieldExpr(.content) else { return nil }
            return .function(.abs, arguments: [arg])
        case .vector:
            guard let content = fieldExpr(.content) else { return nil }
            if case .tuple(let values) = content {
                return .vector(values)
            }
            return .vector([content])
        case .sin, .cos, .tan, .ln, .exp:
            guard let arg = fieldExpr(.argument) else { return nil }
            let fn: MathFunction
            switch template.kind {
            case .sin: fn = .sin
            case .cos: fn = .cos
            case .tan: fn = .tan
            case .ln: fn = .ln
            case .exp: fn = .exp
            default: fn = .custom("unknown")
            }
            return .function(fn, arguments: [arg])
        case .log:
            guard let arg = fieldExpr(.argument) else { return nil }
            if let base = template.field(.base),
               !base.isEmptyForEditing,
               let baseExpr = lowerNode(base, path: path.appending(.field(fieldName(.base))), context: context, diagnostics: &diagnostics, sourceMap: &sourceMap) {
                return .function(.log, arguments: [baseExpr, arg])
            }
            return .function(.log, arguments: [arg])
        case .piecewise(let rows):
            var branches: [PiecewiseBranch] = []
            for row in 0..<rows {
                guard let value = fieldExpr(.rowExpression(row)),
                      let condition = fieldExpr(.rowCondition(row)) else {
                    return nil
                }
                branches.append(PiecewiseBranch(value: value, condition: condition))
            }
            return .piecewise(branches: branches, otherwise: nil)
        case .cases(let rows):
            var values: [Expr] = []
            for row in 0..<rows {
                guard let value = fieldExpr(.rowExpression(row)) else { return nil }
                values.append(value)
            }
            return .tuple(values)
        case .matrix(let rows, let cols):
            var resultRows: [[Expr]] = []
            for row in 0..<rows {
                var resultCols: [Expr] = []
                for col in 0..<cols {
                    guard let cell = fieldExpr(.matrixCell(row: row, col: col)) else { return nil }
                    resultCols.append(cell)
                }
                resultRows.append(resultCols)
            }
            return .matrix(MatrixExpr(rows: resultRows))
        case .parametricEquation2D:
            guard let xExpr = fieldExpr(.parametricExpression(0)),
                  let yExpr = fieldExpr(.parametricExpression(1)) else { return nil }
            var items: [Expr] = [
                .relation(
                    left: .symbol(Symbol(name: "x", role: .variable)),
                    relation: .equal,
                    right: xExpr
                ),
                .relation(
                    left: .symbol(Symbol(name: "y", role: .variable)),
                    relation: .equal,
                    right: yExpr
                )
            ]
            if let rangeNode = template.field(.parametricRange),
               !rangeNode.isEmptyForEditing,
               let rangeExpr = lowerNode(
                    rangeNode,
                    path: path.appending(.field(fieldName(.parametricRange))),
                    context: context,
                    diagnostics: &diagnostics,
                    sourceMap: &sourceMap
               ) {
                items.append(rangeExpr)
            }
            return .tuple(items)
        case .parametricEquation3D:
            guard let xExpr = fieldExpr(.parametricExpression(0)),
                  let yExpr = fieldExpr(.parametricExpression(1)),
                  let zExpr = fieldExpr(.parametricExpression(2)) else { return nil }
            return .tuple([xExpr, yExpr, zExpr])
        case .overline, .hat:
            guard let content = fieldExpr(.content) else { return nil }
            return content
        case .limit, .sum, .product, .integral:
            emit(.warning, .unsupportedEditorNode, "当前 lowering 暂未支持模板: \(template.kind)", path: path, diagnostics: &diagnostics)
            return .unknown("\(template.kind)")
        }
    }

    private func lowerSequence(
        _ nodes: [MathNode],
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> Expr? {
        guard !nodes.isEmpty else {
            emit(.error, .emptyExpression, "空表达式", path: path, diagnostics: &diagnostics)
            return nil
        }

        let trimmedNodes = trimWhitespaceNodes(nodes)
        guard !trimmedNodes.isEmpty else {
            emit(.error, .emptyExpression, "表达式为空", path: path, diagnostics: &diagnostics)
            return nil
        }

        // Support character-level grouped tuples like "(sin(a), cos(a))" without relying on
        // template wrappers, so commit and preview keep the same semantic intent.
        if let unwrapped = unwrapSingleOuterParentheses(trimmedNodes) {
            let tupleItems = splitTopLevelCommas(unwrapped)
            if tupleItems.count > 1 {
                var values: [Expr] = []
                for (idx, item) in tupleItems.enumerated() {
                    let itemPath = path.appending(.index(idx))
                    guard let lowered = lowerSequence(
                        item,
                        path: itemPath,
                        context: context,
                        diagnostics: &diagnostics,
                        sourceMap: &sourceMap
                    ) else {
                        return nil
                    }
                    values.append(lowered)
                }
                return .tuple(values)
            }
            return lowerSequence(
                unwrapped,
                path: path,
                context: context,
                diagnostics: &diagnostics,
                sourceMap: &sourceMap
            )
        }

        let tokens = tokenize(trimmedNodes, path: path, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)
        guard !tokens.isEmpty else {
            emit(.error, .emptyExpression, "表达式为空", path: path, diagnostics: &diagnostics)
            return nil
        }
        var parser = SequenceParser(tokens: tokens)
        guard let parsed = parser.parse() else {
            diagnostics.append(contentsOf: parser.diagnostics)
            return nil
        }
        diagnostics.append(contentsOf: parser.diagnostics)
        sourceMap[path] = ExprSourceLocation(path: path)
        return adaptTopLevel(parsed, mode: context.mode, diagnostics: &diagnostics, path: path)
    }

    private func adaptTopLevel(
        _ expr: Expr,
        mode: LoweringMode,
        diagnostics: inout [ExprDiagnostic],
        path: ExprPath
    ) -> Expr {
        switch mode {
        case .equationInput, .expression:
            if case .relation(let left, let relation, let right) = expr, relation == .equal {
                return .equation(left: left, right: right)
            }
            return expr
        case .objectDefinition:
            if case .relation(let left, let relation, let right) = expr, relation == .equal {
                if let definition = makeObjectDefinition(left: left, right: right, diagnostics: &diagnostics, path: path) {
                    return definition
                }
                return .assignment(target: left, value: right)
            }
            return expr
        case .condition:
            return expr
        }
    }

    private func makeObjectDefinition(
        left: Expr,
        right: Expr,
        diagnostics: inout [ExprDiagnostic],
        path: ExprPath
    ) -> Expr? {
        if case .function(let fn, let arguments) = left,
           case .custom(let rawName) = fn {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                emit(.error, .unsupportedExpression, "函数定义左侧函数名为空", path: path, diagnostics: &diagnostics)
                return nil
            }
            var params: [Symbol] = []
            for arg in arguments {
                guard case .symbol(let symbol) = arg else {
                    emit(.error, .unsupportedExpression, "函数定义参数必须是符号", path: path, diagnostics: &diagnostics)
                    return nil
                }
                params.append(Symbol(name: symbol.name, role: .parameter, namespace: symbol.namespace))
            }
            return .functionDefinition(
                name: Symbol(name: name, role: .function),
                parameters: params,
                body: right
            )
        }
        return .assignment(target: left, value: right)
    }

    private func tokenize(
        _ nodes: [MathNode],
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> [SequenceToken] {
        var result: [SequenceToken] = []
        var index = 0

        func nodePath(_ i: Int) -> ExprPath {
            path.appending(.index(i))
        }

        while index < nodes.count {
            let node = nodes[index]

            if let combined = consumeCombinedOperator(nodes, start: index) {
                result.append(.operatorSymbol(combined.operatorText))
                index = combined.nextIndex
                continue
            }

            if let latexRelation = consumeLatexRelationOperator(nodes, start: index) {
                result.append(.operatorSymbol(latexRelation.operatorText))
                index = latexRelation.nextIndex
                continue
            }

            switch node {
            case .placeholder:
                emit(.error, .unresolvedPlaceholder, "表达式包含未完成占位符", path: nodePath(index), diagnostics: &diagnostics)
                index += 1
            case .operatorSymbol(let op):
                let normalized = MathInputCharacterNormalizer.normalize(op)
                if normalized == "," {
                    result.append(.comma)
                    index += 1
                    continue
                }
                if isOperatorText(normalized) {
                    result.append(.operatorSymbol(normalized))
                } else {
                    // Keep non-operator symbols as normalized text so downstream
                    // grouping helpers can recognize full-width punctuation.
                    result.append(.operatorSymbol(normalized))
                }
                index += 1
            case .character(let text):
                let normalized = MathInputCharacterNormalizer.normalize(text)
                if normalized == "," {
                    result.append(.comma)
                    index += 1
                    continue
                }
                if normalized == "(",
                   let grouped = consumeCharacterParenthesizedGroup(
                        nodes,
                        start: index,
                        path: path,
                        context: context,
                        diagnostics: &diagnostics,
                        sourceMap: &sourceMap
                   ) {
                    result.append(.atom(grouped.expr))
                    sourceMap[grouped.path] = ExprSourceLocation(path: grouped.path)
                    index = grouped.endIndex
                    continue
                }
                if isOperatorText(normalized) {
                    result.append(.operatorSymbol(normalized))
                    index += 1
                    continue
                }
                if normalized.first?.isWhitespace == true {
                    index += 1
                    continue
                }
                if let numberToken = consumeNumber(nodes, start: index, path: path, diagnostics: &diagnostics, consumed: &index) {
                    result.append(.atom(numberToken.expr))
                    sourceMap[numberToken.path] = ExprSourceLocation(path: numberToken.path)
                    continue
                }
                if let identifierToken = consumeIdentifierOrFunction(nodes, start: index, path: path, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap, consumed: &index) {
                    result.append(.atom(identifierToken.expr))
                    sourceMap[identifierToken.path] = ExprSourceLocation(path: identifierToken.path)
                    continue
                }
                emit(.error, .unsupportedEditorNode, "无法识别字符节点: \(text)", path: nodePath(index), diagnostics: &diagnostics)
                index += 1
            case .symbol(let symbolText):
                let normalized = MathInputCharacterNormalizer.normalize(symbolText)
                if normalized == "," {
                    result.append(.comma)
                    index += 1
                    continue
                }
                if isOperatorText(normalized) {
                    result.append(.operatorSymbol(normalized))
                    index += 1
                    continue
                }
                let symbolExpr = Expr.symbol(Symbol(name: normalized, role: .unknown))
                let symbolPath = nodePath(index)
                result.append(.atom(symbolExpr))
                sourceMap[symbolPath] = ExprSourceLocation(path: symbolPath)
                index += 1
            case .template(let template):
                if case .parentheses = template.kind {
                    if let previous = result.last, case .atom(let lhsExpr) = previous,
                       let functionName = functionNameFromExpr(lhsExpr) {
                        _ = result.popLast()
                        let argumentPath = nodePath(index).appending(.field(fieldName(.content)))
                        guard let argumentNode = template.field(.content),
                              let loweredArg = lowerNode(argumentNode, path: argumentPath, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap) else {
                            index += 1
                            continue
                        }
                        let arguments: [Expr]
                        if case .tuple(let values) = loweredArg {
                            arguments = values
                        } else {
                            arguments = [loweredArg]
                        }
                        let loweredFunction = Expr.function(resolveFunction(name: functionName), arguments: arguments)
                        result.append(.atom(loweredFunction))
                        sourceMap[nodePath(index)] = ExprSourceLocation(path: nodePath(index))
                        index += 1
                        continue
                    }
                }

                let templatePath = nodePath(index)
                if let lowered = lowerTemplate(template, path: templatePath, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap) {
                    result.append(.atom(lowered))
                    sourceMap[templatePath] = ExprSourceLocation(path: templatePath)
                }
                index += 1
            case .sequence(let nested):
                let nestedPath = nodePath(index)
                if let lowered = lowerSequence(nested, path: nestedPath, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap) {
                    result.append(.atom(lowered))
                    sourceMap[nestedPath] = ExprSourceLocation(path: nestedPath)
                }
                index += 1
            }
        }
        return result
    }

    private func consumeCombinedOperator(
        _ nodes: [MathNode],
        start: Int
    ) -> (operatorText: String, nextIndex: Int)? {
        guard start + 1 < nodes.count,
              let first = normalizedNodeText(nodes[start]),
              let second = normalizedNodeText(nodes[start + 1]) else {
            return nil
        }
        let merged = first + second
        switch merged {
        case "<=", ">=", "!=", "==", "~=":
            return (merged, start + 2)
        default:
            return nil
        }
    }

    private func consumeLatexRelationOperator(
        _ nodes: [MathNode],
        start: Int
    ) -> (operatorText: String, nextIndex: Int)? {
        guard let first = normalizedNodeText(nodes[start]) else { return nil }

        // Path A: command already arrives as a single token, e.g. .symbol("\\geq")
        // or .operatorSymbol("\\le").
        switch first.lowercased() {
        case "\\geq", "\\ge":
            return (">=", start + 1)
        case "\\leq", "\\le":
            return ("<=", start + 1)
        default:
            break
        }

        // Path B: command split into "\" + letters (possibly as one token "geq").
        guard first == "\\" else { return nil }
        var cursor = start + 1
        var command = "\\"

        if cursor < nodes.count, let next = normalizedNodeText(nodes[cursor]) {
            let lowered = next.lowercased()
            if lowered == "geq" || lowered == "ge" || lowered == "leq" || lowered == "le" {
                command.append(lowered)
                cursor += 1
            } else {
                while cursor < nodes.count,
                      let current = normalizedNodeText(nodes[cursor]),
                      current.count == 1,
                      let scalar = current.unicodeScalars.first,
                      CharacterSet.letters.contains(scalar) {
                    command.append(current)
                    cursor += 1
                }
            }
        }
        switch command.lowercased() {
        case "\\geq", "\\ge":
            return (">=", cursor)
        case "\\leq", "\\le":
            return ("<=", cursor)
        default:
            return nil
        }
    }

    private func consumeNumber(
        _ nodes: [MathNode],
        start: Int,
        path: ExprPath,
        diagnostics: inout [ExprDiagnostic],
        consumed: inout Int
    ) -> (expr: Expr, path: ExprPath)? {
        var i = start
        var raw = ""
        var dotCount = 0

        func char(at index: Int) -> String? {
            guard index < nodes.count, case .character(let value) = nodes[index] else { return nil }
            return value
        }

        guard let first = char(at: i), isDigitOrDot(first) else { return nil }

        while let current = char(at: i), isDigitOrDot(current) {
            if current == "." { dotCount += 1 }
            raw.append(current)
            i += 1
        }
        consumed = i

        if dotCount > 1 || raw == "." {
            emit(.error, .invalidNumberLiteral, "非法数字字面量: \(raw)", path: path.appending(.index(start)), diagnostics: &diagnostics)
            return nil
        }
        if raw.contains(".") {
            return (.decimal(raw), path.appending(.index(start)))
        }
        if let value = Int(raw) {
            return (.integer(value), path.appending(.index(start)))
        }
        emit(.error, .invalidNumberLiteral, "整数超出范围: \(raw)", path: path.appending(.index(start)), diagnostics: &diagnostics)
        return nil
    }

    private func consumeIdentifierOrFunction(
        _ nodes: [MathNode],
        start: Int,
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation],
        consumed: inout Int
    ) -> (expr: Expr, path: ExprPath)? {
        var i = start
        var raw = ""

        func char(at index: Int) -> String? {
            guard index < nodes.count, case .character(let value) = nodes[index] else { return nil }
            return MathInputCharacterNormalizer.normalize(value)
        }

        guard let first = char(at: i) else { return nil }
        if first == "\\" {
            raw.append(first)
            i += 1
            while let current = char(at: i), isIdentifierLetter(current) {
                raw.append(current)
                i += 1
            }
            guard raw.count > 1 else { return nil }
        } else {
            guard isIdentifierChar(first) else { return nil }
            while let current = char(at: i), isIdentifierChar(current) {
                raw.append(current)
                i += 1
            }
        }

        if i < nodes.count {
            if case .template(let template) = nodes[i],
               case .parentheses = template.kind {
                let argumentPath = path.appending(.index(i)).appending(.field(fieldName(.content)))
                guard let argumentNode = template.field(.content),
                      let loweredArg = lowerNode(argumentNode, path: argumentPath, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap) else {
                    consumed = i + 1
                    emit(.error, .missingArgument, "函数参数缺失: \(raw)(...)", path: path.appending(.index(i)), diagnostics: &diagnostics)
                    return nil
                }
                let args: [Expr]
                if case .tuple(let values) = loweredArg {
                    args = values
                } else {
                    args = [loweredArg]
                }
                consumed = i + 1
                return (.function(resolveFunction(name: raw), arguments: args), path.appending(.index(start)))
            }

            if let (args, endIndex) = consumeFunctionCallArgumentsInCharacterParentheses(
                nodes,
                start: i,
                path: path,
                context: context,
                diagnostics: &diagnostics,
                sourceMap: &sourceMap
            ) {
                consumed = endIndex
                return (.function(resolveFunction(name: raw), arguments: args), path.appending(.index(start)))
            }
        }

        consumed = i
        if let constant = resolveNamedConstant(raw) {
            return (constant, path.appending(.index(start)))
        }
        if let implicitProduct = implicitProductExpr(from: raw, context: context) {
            return (implicitProduct, path.appending(.index(start)))
        }
        if let decomposed = decomposeKnownImplicitProduct(from: raw, context: context) {
            return (decomposed, path.appending(.index(start)))
        }
        return (.symbol(Symbol(name: raw, role: .unknown)), path.appending(.index(start)))
    }

    private func implicitProductExpr(from raw: String, context: LoweringContext) -> Expr? {
        let protectedFunctions: Set<String> = [
            "sin", "cos", "tan", "asin", "acos", "atan",
            "sinh", "cosh", "tanh",
            "ln", "lg", "log", "sqrt", "exp", "abs", "floor", "ceil", "min", "max"
        ]
        let lowerRaw = raw.lowercased()
        guard !protectedFunctions.contains(lowerRaw) else { return nil }

        let knownParameterNames = Set(
            context.symbolTable.symbols.values
                .filter { $0.role == .parameter }
                .map(\.name)
        )
        guard !knownParameterNames.isEmpty else { return nil }

        let allowedSuffixes: Set<String> = ["x", "y", "t", "u", "v", "s", "r"]
        for parameterName in knownParameterNames.sorted(by: { $0.count > $1.count }) {
            guard raw.hasPrefix(parameterName), raw.count > parameterName.count else { continue }
            let suffix = String(raw.dropFirst(parameterName.count))
            guard allowedSuffixes.contains(suffix) else { continue }
            return .multiply([
                .symbol(Symbol(name: parameterName, role: .parameter)),
                .symbol(Symbol(name: suffix, role: .unknown))
            ])
        }
        return nil
    }

    private func decomposeKnownImplicitProduct(from raw: String, context: LoweringContext) -> Expr? {
        guard raw.count >= 2 else { return nil }
        guard raw.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil else { return nil }
        guard raw.range(of: "_") == nil else { return nil }

        let protectedFunctions: Set<String> = [
            "sin", "cos", "tan", "asin", "acos", "atan",
            "sinh", "cosh", "tanh",
            "ln", "lg", "log", "sqrt", "exp", "abs", "floor", "ceil", "min", "max",
            "pi"
        ]
        let lowerRaw = raw.lowercased()
        guard !protectedFunctions.contains(lowerRaw) else { return nil }

        let parameterNames = Set(
            context.symbolTable.symbols.values
                .filter { $0.role == .parameter }
                .map(\.name)
                .filter { $0.count == 1 }
        )
        let knownSingle: Set<String> = Set(["x", "y", "t", "u", "v", "s", "r"])
            .union(parameterNames)

        let letters = raw.map(String.init)
        guard letters.allSatisfy({ knownSingle.contains($0) }) else { return nil }
        guard letters.contains(where: { $0 == "x" || $0 == "y" || $0 == "t" }) || letters.count == 2 else {
            return nil
        }

        let factors = letters.map { Expr.symbol(Symbol(name: $0, role: .unknown)) }
        return .multiply(factors)
    }

    private func parseNumericLiteral(
        _ raw: String,
        path: ExprPath,
        diagnostics: inout [ExprDiagnostic]
    ) -> Expr? {
        if raw.allSatisfy({ $0.isNumber }) {
            if let int = Int(raw) {
                return .integer(int)
            }
            emit(.error, .invalidNumberLiteral, "整数超出范围: \(raw)", path: path, diagnostics: &diagnostics)
            return nil
        }
        if raw.first?.isNumber == true && raw.contains(".") {
            let dotCount = raw.filter { $0 == "." }.count
            guard dotCount == 1, raw != "." else {
                emit(.error, .invalidNumberLiteral, "非法数字字面量: \(raw)", path: path, diagnostics: &diagnostics)
                return nil
            }
            return .decimal(raw)
        }
        return nil
    }

    private func resolveFunction(name: String) -> MathFunction {
        switch name.lowercased() {
        case "sin": return .sin
        case "cos": return .cos
        case "tan": return .tan
        case "asin": return .asin
        case "acos": return .acos
        case "atan": return .atan
        case "sinh": return .sinh
        case "cosh": return .cosh
        case "tanh": return .tanh
        case "exp": return .exp
        case "ln": return .ln
        case "lg": return .lg
        case "log": return .log
        case "sqrt": return .sqrt
        case "abs": return .abs
        case "floor": return .floor
        case "ceil": return .ceil
        case "min": return .min
        case "max": return .max
        default: return .custom(name)
        }
    }

    private func functionNameFromExpr(_ expr: Expr) -> String? {
        if case .symbol(let symbol) = expr {
            return symbol.name
        }
        return nil
    }

    private func isDigitOrDot(_ value: String) -> Bool {
        let normalized = MathInputCharacterNormalizer.normalize(value)
        guard normalized.count == 1, let scalar = normalized.unicodeScalars.first else { return false }
        return CharacterSet.decimalDigits.contains(scalar) || normalized == "."
    }

    private func isIdentifierChar(_ value: String) -> Bool {
        let normalized = MathInputCharacterNormalizer.normalize(value)
        guard normalized.count == 1, let scalar = normalized.unicodeScalars.first else { return false }
        return CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) || normalized == "_"
    }

    private func isIdentifierLetter(_ value: String) -> Bool {
        let normalized = MathInputCharacterNormalizer.normalize(value)
        guard normalized.count == 1, let scalar = normalized.unicodeScalars.first else { return false }
        return CharacterSet.letters.contains(scalar)
    }

    private func isOperatorText(_ value: String) -> Bool {
        ["+", "-", "*", "/", "^", "=", "<", ">", "<=", ">=", "≤", "≥", "≈", "!=", "=="].contains(value)
    }

    private func fieldName(_ field: FieldID) -> String {
        switch field {
        case .numerator: return "numerator"
        case .denominator: return "denominator"
        case .radicand: return "radicand"
        case .rootIndex: return "rootIndex"
        case .base: return "base"
        case .exponent: return "exponent"
        case .subscriptField: return "subscriptField"
        case .content: return "content"
        case .argument: return "argument"
        case .lowerBound: return "lowerBound"
        case .upperBound: return "upperBound"
        case .integrand: return "integrand"
        case .variable: return "variable"
        case .target: return "target"
        case .expression: return "expression"
        case .rowExpression(let row): return "rowExpression[\(row)]"
        case .rowCondition(let row): return "rowCondition[\(row)]"
        case .matrixCell(let row, let col): return "matrixCell[\(row),\(col)]"
        case .parametricExpression(let idx): return "parametricExpression[\(idx)]"
        case .parametricRange: return "parametricRange"
        }
    }

    private func resolveNamedConstant(_ raw: String) -> Expr? {
        let normalized = MathInputCharacterNormalizer.normalize(raw)
        switch normalized {
        case "π", "pi", "PI", "\\pi", "\\PI":
            return .constant(.pi)
        case "e":
            return .constant(.e)
        default:
            return nil
        }
    }

    private func consumeFunctionCallArgumentsInCharacterParentheses(
        _ nodes: [MathNode],
        start: Int,
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> (arguments: [Expr], endIndex: Int)? {
        guard isOpenParenNode(nodes[start]) else { return nil }

        var depth = 0
        var cursor = start
        var segmentStart = start + 1
        var segments: [[MathNode]] = []

        while cursor < nodes.count {
            if isOpenParenNode(nodes[cursor]) {
                depth += 1
            } else if isCloseParenNode(nodes[cursor]) {
                depth -= 1
                if depth == 0 {
                    segments.append(Array(nodes[segmentStart..<cursor]))
                    cursor += 1
                    break
                }
            } else if depth == 1, isCommaNode(nodes[cursor]) {
                segments.append(Array(nodes[segmentStart..<cursor]))
                segmentStart = cursor + 1
            }
            cursor += 1
        }

        guard depth == 0 else { return nil }

        if segments.isEmpty {
            return ([], cursor)
        }

        var arguments: [Expr] = []
        for (segmentIndex, segment) in segments.enumerated() {
            let segmentPath = path.appending(.index(start)).appending(.field("argument[\(segmentIndex)]"))
            guard let arg = lowerArgumentSegment(
                segment,
                path: segmentPath,
                context: context,
                diagnostics: &diagnostics,
                sourceMap: &sourceMap
            ) else {
                return nil
            }
            arguments.append(arg)
        }

        return (arguments, cursor)
    }

    private func consumeCharacterParenthesizedGroup(
        _ nodes: [MathNode],
        start: Int,
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> (expr: Expr, endIndex: Int, path: ExprPath)? {
        guard isOpenParenNode(nodes[start]) else { return nil }

        var depth = 0
        var cursor = start
        while cursor < nodes.count {
            if isOpenParenNode(nodes[cursor]) {
                depth += 1
            } else if isCloseParenNode(nodes[cursor]) {
                depth -= 1
                if depth == 0 {
                    let content = Array(nodes[(start + 1)..<cursor])
                    let groupPath = path.appending(.index(start)).appending(.field("group"))
                    guard let lowered = lowerArgumentSegment(
                        content,
                        path: groupPath,
                        context: context,
                        diagnostics: &diagnostics,
                        sourceMap: &sourceMap
                    ) else {
                        return nil
                    }
                    return (lowered, cursor + 1, groupPath)
                }
            }
            cursor += 1
        }

        emit(.error, .unsupportedEditorNode, "括号未闭合", path: path.appending(.index(start)), diagnostics: &diagnostics)
        return nil
    }

    private func lowerArgumentSegment(
        _ segment: [MathNode],
        path: ExprPath,
        context: LoweringContext,
        diagnostics: inout [ExprDiagnostic],
        sourceMap: inout [ExprPath: ExprSourceLocation]
    ) -> Expr? {
        let trimmed = trimWhitespaceNodes(segment)
        guard !trimmed.isEmpty else {
            emit(.error, .missingArgument, "函数参数缺失", path: path, diagnostics: &diagnostics)
            return nil
        }

        if let unwrapped = unwrapSingleOuterParentheses(trimmed) {
            let tupleItems = splitTopLevelCommas(unwrapped)
            if tupleItems.count > 1 {
                var values: [Expr] = []
                for (idx, item) in tupleItems.enumerated() {
                    let itemPath = path.appending(.index(idx))
                    guard let lowered = lowerSequence(item, path: itemPath, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap) else {
                        return nil
                    }
                    values.append(lowered)
                }
                return .tuple(values)
            }
            return lowerSequence(unwrapped, path: path, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)
        }

        return lowerSequence(trimmed, path: path, context: context, diagnostics: &diagnostics, sourceMap: &sourceMap)
    }

    private func trimWhitespaceNodes(_ nodes: [MathNode]) -> [MathNode] {
        var start = 0
        var end = nodes.count
        while start < end, isWhitespaceNode(nodes[start]) { start += 1 }
        while end > start, isWhitespaceNode(nodes[end - 1]) { end -= 1 }
        return Array(nodes[start..<end])
    }

    private func unwrapSingleOuterParentheses(_ nodes: [MathNode]) -> [MathNode]? {
        guard nodes.count >= 2, isOpenParenNode(nodes[0]), isCloseParenNode(nodes[nodes.count - 1]) else { return nil }
        var depth = 0
        for (idx, node) in nodes.enumerated() {
            if isOpenParenNode(node) {
                depth += 1
            } else if isCloseParenNode(node) {
                depth -= 1
                if depth == 0 && idx < nodes.count - 1 {
                    return nil
                }
            }
        }
        guard depth == 0 else { return nil }
        return Array(nodes[1..<(nodes.count - 1)])
    }

    private func splitTopLevelCommas(_ nodes: [MathNode]) -> [[MathNode]] {
        var result: [[MathNode]] = []
        var depth = 0
        var start = 0
        for i in nodes.indices {
            let node = nodes[i]
            if isOpenParenNode(node) {
                depth += 1
                continue
            }
            if isCloseParenNode(node) {
                depth -= 1
                continue
            }
            if depth == 0, isCommaNode(node) {
                result.append(Array(nodes[start..<i]))
                start = i + 1
            }
        }
        result.append(Array(nodes[start..<nodes.count]))
        return result
    }

    private func normalizedNodeText(_ node: MathNode) -> String? {
        switch node {
        case .character(let raw):
            return MathInputCharacterNormalizer.normalize(raw)
        case .operatorSymbol(let raw):
            return MathInputCharacterNormalizer.normalize(raw)
        default:
            return nil
        }
    }

    private func isOpenParenNode(_ node: MathNode) -> Bool {
        guard let text = normalizedNodeText(node) else { return false }
        return text == "("
    }

    private func isCloseParenNode(_ node: MathNode) -> Bool {
        guard let text = normalizedNodeText(node) else { return false }
        return text == ")"
    }

    private func isCommaNode(_ node: MathNode) -> Bool {
        guard let text = normalizedNodeText(node) else { return false }
        return text == ","
    }

    private func isWhitespaceNode(_ node: MathNode) -> Bool {
        guard let text = normalizedNodeText(node) else { return false }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func emit(
        _ severity: ExprDiagnosticSeverity,
        _ code: ExprDiagnosticCode,
        _ message: String,
        path: ExprPath,
        diagnostics: inout [ExprDiagnostic]
    ) {
        diagnostics.append(
            ExprDiagnostic(
                severity: severity,
                code: code,
                message: message,
                location: ExprSourceLocation(path: path)
            )
        )
    }
}

private extension ExprPath {
    public func appending(_ component: ExprPathComponent) -> ExprPath {
        var copy = self
        copy.components.append(component)
        return copy
    }
}

private enum SequenceToken {
    case atom(Expr)
    case operatorSymbol(String)
    case comma
}

private struct SequenceParser {
    public let tokens: [SequenceToken]
    public var index: Int = 0
    public var diagnostics: [ExprDiagnostic] = []

    public mutating func parse() -> Expr? {
        let tuples = parseTupleItems()
        guard !tuples.isEmpty else { return nil }
        if tuples.count == 1 { return tuples[0] }
        return .tuple(tuples)
    }

    private mutating func parseTupleItems() -> [Expr] {
        var items: [Expr] = []
        if let first = parseRelation() {
            items.append(first)
        } else {
            return []
        }
        while matchComma() {
            guard let item = parseRelation() else {
                diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "逗号后缺少表达式", location: nil))
                break
            }
            items.append(item)
        }
        return items
    }

    private mutating func parseRelation() -> Expr? {
        guard let first = parseAdditive() else { return nil }

        var expressions: [Expr] = [first]
        var relations: [RelationOperator] = []

        while let relation = matchRelationOperator() {
            guard let rhs = parseAdditive() else {
                diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "关系运算符右侧缺少表达式", location: nil))
                return nil
            }
            relations.append(relation)
            expressions.append(rhs)
        }

        if relations.isEmpty {
            return first
        }
        if relations.count == 1 {
            return .relation(left: expressions[0], relation: relations[0], right: expressions[1])
        }
        return .chainedRelation(expressions: expressions, relations: relations)
    }

    private mutating func parseAdditive() -> Expr? {
        guard var expr = parseMultiplicative() else { return nil }
        while true {
            if matchOperator("+") {
                guard let rhs = parseMultiplicative() else {
                    diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "加号右侧缺少表达式", location: nil))
                    return nil
                }
                expr = .add([expr, rhs])
            } else if matchOperator("-") {
                guard let rhs = parseMultiplicative() else {
                    diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "减号右侧缺少表达式", location: nil))
                    return nil
                }
                expr = .add([expr, .negate(rhs)])
            } else {
                return expr
            }
        }
    }

    private mutating func parseMultiplicative() -> Expr? {
        guard var expr = parseUnary() else { return nil }

        while true {
            if matchOperator("*") {
                guard let rhs = parseUnary() else {
                    diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "乘号右侧缺少表达式", location: nil))
                    return nil
                }
                expr = .multiply([expr, rhs])
                continue
            }
            if matchOperator("/") {
                guard let rhs = parseUnary() else {
                    diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "除号右侧缺少表达式", location: nil))
                    return nil
                }
                expr = .divide(numerator: expr, denominator: rhs)
                continue
            }
            if shouldImplicitMultiply(next: peek()) {
                guard let rhs = parseUnary() else {
                    diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "隐式乘法右侧缺少表达式", location: nil))
                    return nil
                }
                expr = .multiply([expr, rhs])
                continue
            }
            return expr
        }
    }

    private mutating func parseUnary() -> Expr? {
        if matchOperator("-") {
            guard let operand = parseUnary() else {
                diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "负号后缺少表达式", location: nil))
                return nil
            }
            return .negate(operand)
        }
        return parsePower()
    }

    private mutating func parsePower() -> Expr? {
        guard var lhs = parsePrimary() else { return nil }
        while matchOperator("^") {
            guard let rhs = parseUnary() else {
                diagnostics.append(ExprDiagnostic(severity: .error, code: .missingOperand, message: "幂指数缺失", location: nil))
                return nil
            }
            lhs = .power(base: lhs, exponent: rhs)
        }
        return lhs
    }

    private mutating func parsePrimary() -> Expr? {
        switch peek() {
        case .atom(let expr):
            _ = advance()
            if let function = unparenthesizedFunction(from: expr),
               canStartFunctionArgument(peek()),
               let argument = parseUnary() {
                return .function(function, arguments: [argument])
            }
            return expr
        default:
            return nil
        }
    }

    private func canStartFunctionArgument(_ token: SequenceToken?) -> Bool {
        guard let token else { return false }
        if case .atom = token { return true }
        if case .operatorSymbol(let op) = token, op == "-" { return true }
        return false
    }

    private func unparenthesizedFunction(from expr: Expr) -> MathFunction? {
        guard case .symbol(let symbol) = expr else { return nil }
        switch symbol.name.lowercased() {
        case "sin": return .sin
        case "cos": return .cos
        case "tan": return .tan
        case "asin": return .asin
        case "acos": return .acos
        case "atan": return .atan
        case "sinh": return .sinh
        case "cosh": return .cosh
        case "tanh": return .tanh
        case "exp": return .exp
        case "ln": return .ln
        case "lg": return .lg
        case "log": return .log
        case "sqrt": return .sqrt
        case "abs": return .abs
        case "floor": return .floor
        case "ceil": return .ceil
        default: return nil
        }
    }

    private func shouldImplicitMultiply(next token: SequenceToken?) -> Bool {
        guard let token else { return false }
        if case .atom = token { return true }
        return false
    }

    private mutating func matchRelationOperator() -> RelationOperator? {
        guard case .operatorSymbol(let op)? = peek() else { return nil }
        let relation: RelationOperator?
        switch op {
        case "=": relation = .equal
        case "!=": relation = .notEqual
        case "<": relation = .less
        case "<=","≤": relation = .lessOrEqual
        case ">": relation = .greater
        case ">=","≥": relation = .greaterOrEqual
        case "≈","~=": relation = .approximatelyEqual
        default: relation = nil
        }
        if let relation {
            _ = advance()
            return relation
        }
        return nil
    }

    private mutating func matchOperator(_ symbol: String) -> Bool {
        guard case .operatorSymbol(let op)? = peek(), op == symbol else { return false }
        _ = advance()
        return true
    }

    private mutating func matchComma() -> Bool {
        guard case .comma? = peek() else { return false }
        _ = advance()
        return true
    }

    private func peek() -> SequenceToken? {
        guard index < tokens.count else { return nil }
        return tokens[index]
    }

    @discardableResult
    private mutating func advance() -> SequenceToken? {
        guard index < tokens.count else { return nil }
        let value = tokens[index]
        index += 1
        return value
    }
}
