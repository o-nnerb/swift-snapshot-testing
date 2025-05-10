import UIKit

@MainActor
private var kUIViewControllerLock = 0

extension UIViewController {

    private var lock: AsyncLock {
        if let lock = objc_getAssociatedObject(self, &kUIViewControllerLock) as? AsyncLock {
            return lock
        }

        let lock = AsyncLock()
        objc_setAssociatedObject(self, &kUIViewControllerLock, lock, .OBJC_ASSOCIATION_RETAIN)
        return lock
    }

    fileprivate func withLock<Value: Sendable>(_ body: @Sendable () async throws -> Value) async throws -> Value {
        try await lock.withLock(body)
    }
}

extension SnapshotConfiguration where Input: UIViewController {

    func withLock() -> SnapshotConfiguration {
        map { pipeline in
            Pipeline.start(Input.self) { view in
                try await view.withLock {
                    try await pipeline(view)
                }
            }
        }
    }
}
