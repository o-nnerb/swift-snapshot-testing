import UIKit
import WebKit

extension UIView {

    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

    func withController() -> UIViewController {
        UIViewHostingController(self)
    }

    func waitLoadingStateIfNeeded() async {
        if let webView = self as? WKWebView {
            return await webView.waitLoadingState()
        }

        for subview in subviews {
            await subview.waitLoadingStateIfNeeded()
        }
    }
}

private class UIViewHostingController: UIViewController {

    private let contentView: UIView

    init(_ contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = contentView
    }
}

@MainActor
private var kUIViewLock = 0

extension UIView {

    private var lock: AsyncLock {
        if let lock = objc_getAssociatedObject(self, &kUIViewLock) as? AsyncLock {
            return lock
        }

        let lock = AsyncLock()
        objc_setAssociatedObject(self, &kUIViewLock, lock, .OBJC_ASSOCIATION_RETAIN)
        return lock
    }

    fileprivate func withLock<Value: Sendable>(_ body: @Sendable () async throws -> Value) async throws -> Value {
        try await lock.withLock(body)
    }
}

extension SnapshotConfiguration where Input: UIView {

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
