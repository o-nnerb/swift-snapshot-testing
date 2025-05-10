import UIKit

extension UIWindow {

    @discardableResult
    func switchRoot(
        _ viewController: UIViewController
    ) -> UIViewController? {
        let previousRootViewController = rootViewController
        rootViewController = viewController
        return previousRootViewController
    }
}

extension UIWindow {

    private class _Internal: UIWindow {

        init(windowScene: UIWindowScene?, size: CGSize) {
            defer { isHidden = false }

            guard let windowScene else {
                super.init(frame: .init(origin: .zero, size: size))
                return
            }

            super.init(windowScene: windowScene)

            frame = .init(origin: .zero, size: CGSize(
                width: size.width == .zero ? frame.width : size.width,
                height: size.height == .zero ? frame.height : size.height
            ))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    static func make(
        drawHierarchyInKeyWindow: Bool,
        size: CGSize,
        application: UIApplication? = nil
    ) -> UIWindow {
        let application = application ?? UIApplication.sharedIfAvailable
        let windowScenes = application?.windowScenes

        if drawHierarchyInKeyWindow, let keyWindow = windowScenes?.keyWindows.last(where: { !$0.isHidden }) {
            return keyWindow
        } else {
            return _Internal(
                windowScene: windowScenes?.last,
                size: size
            )
        }
    }
}
