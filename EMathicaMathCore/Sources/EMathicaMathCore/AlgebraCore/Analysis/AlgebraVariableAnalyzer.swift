import Foundation

public enum AlgebraVariableAnalyzer {
    public static func variables(in relation: AlgebraRelation, plottingSymbols: Set<String>) -> Set<String> {
        symbols(in: relation).intersection(plottingSymbols)
    }

    public static func parameters(in relation: AlgebraRelation, plottingSymbols: Set<String>) -> Set<String> {
        symbols(in: relation).subtracting(plottingSymbols).subtracting(["pi", "e"])
    }

    private static func symbols(in relation: AlgebraRelation) -> Set<String> {
        switch relation {
        case .expression(let expression):
            return expression.symbols
        case .equation(let equation):
            return equation.left.symbols.union(equation.right.symbols)
        }
    }
}

