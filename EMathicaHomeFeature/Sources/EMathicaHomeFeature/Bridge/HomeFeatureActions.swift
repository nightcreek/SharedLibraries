import Foundation
import EMathicaDocumentKit
import EMathicaWorkspaceKit

@MainActor
public struct HomeFeatureActions {
    var openWorkspace: (HomeWorkspaceOpenRequest) -> Void

    public init(openWorkspace: @escaping (HomeWorkspaceOpenRequest) -> Void) {
        self.openWorkspace = openWorkspace
    }
}

public struct HomeWorkspaceOpenRequest {
    public var module: CalculatorModuleType
    public var document: EMathicaDocument

    public init(module: CalculatorModuleType, document: EMathicaDocument) {
        self.module = module
        self.document = document
    }
}
