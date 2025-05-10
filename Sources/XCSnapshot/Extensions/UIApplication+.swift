import UIKit

extension UIApplication {
    
    static var sharedIfAvailable: UIApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: sharedSelector) else {
            return nil
        }

        let shared = UIApplication.perform(sharedSelector)
        return shared?.takeUnretainedValue() as! UIApplication?
    }

    var windowScenes: [UIWindowScene] {
        connectedScenes.compactMap { $0 as? UIWindowScene }
    }
}

extension Array<UIWindowScene> {

    @MainActor
    var keyWindows: [UIWindow] {
        reduce([]) {
            $0 + $1.windows.filter(\.isKeyWindow)
        }
    }
}
