//
// This file is derived from the SwiftMath project.
// Upstream repository: https://github.com/mgriebling/SwiftMath
// Imported from commit: 1d2c90827e9c3908269d810d055fb03b7da5fd53
// Licensed under the MIT License.
//
// Complete license text and local modification records:
// SharedLibraries/ThirdParty/Licenses/SwiftMath/LICENSE.txt
// SharedLibraries/ThirdParty/Licenses/SwiftMath/MODIFICATIONS.md
//
import Foundation

final class RWLock {
    init() {
        pthread_rwlock_init(&lock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    func read<T>(_ block: () -> T) -> T {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return block()
    }

    func readWrite<T>(_ block: () -> T) -> T {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return block()
    }

    private var lock = pthread_rwlock_t()
}

@propertyWrapper
struct RWLocked<T> {
    init(wrappedValue: T) {
        value = wrappedValue
    }

    var wrappedValue: T {
        get {
            lock.read {
                value
            }
        }
        set {
            lock.readWrite {
                value = newValue
            }
        }
    }

    @discardableResult
    mutating func readWrite(_ block: (inout T) -> Void) -> (oldValue: T, newValue: T) {
        lock.readWrite {
            let old = value
            block(&value)
            return (old, value)
        }
    }

    private var value: T
    private let lock = RWLock()
}
