import UIKit

struct ViewOperationPayload {
    let previousRootViewController: UIViewController?
    let window: UIWindow
    let input: SnapshotUIController
}

extension Pipeline where Output == ViewOperationPayload {

    func waitLoadingStateIfNeeded() -> Pipeline<Input, Output> {
        chain {
            await $0.input.view.waitLoadingStateIfNeeded()
            return $0
        }
    }

    func layoutIfNeeded() -> Pipeline<Input, Output> {
        chain { @MainActor in
            $0.input.layoutIfNeeded()
            return $0
        }
    }

    func snapshot(
        _ pipeline: Pipeline<ImageBytes, ImageBytes>
    ) -> Pipeline<Input, ImageBytes> {
        chain { @MainActor payload in
            let image = try await pipeline(ImageBytes(
                payload.input.snapshot()
            ))

            if let previousRootViewController = payload.previousRootViewController {
                payload.window.rootViewController = previousRootViewController
            }

            payload.input.detachChild()

            if !payload.window.isKeyWindow {
                payload.window.isHidden = true
            }

            return image
        }
    }
}
