import Foundation
import SwiftUI

// MARK: - Error

public enum WorkspaceNavigationError: Error {
    case delegateUnavailable
}

// MARK: - Environment Key

public struct WorkspaceNavigationDelegateKey: @preconcurrency EnvironmentKey {
    @MainActor public static let defaultValue: (any WorkspaceNavigationDelegate)? = nil
}

public extension EnvironmentValues {
    var workspaceNavigationDelegate: (any WorkspaceNavigationDelegate)? {
        get { self[WorkspaceNavigationDelegateKey.self] }
        set { self[WorkspaceNavigationDelegateKey.self] = newValue }
    }
}
