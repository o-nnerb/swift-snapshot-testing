import UIKit

extension UITraitCollection {

    public static func iPhoneSE() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhone8() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhoneX() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhoneXr() -> UITraitCollection {
        baseTraits(forceTouch: .unavailable)
    }

    public static func iPhoneXs() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhone12() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhone13() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhone14() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhone15() -> UITraitCollection {
        baseTraits()
    }

    public static func iPhone16() -> UITraitCollection {
        baseTraits()
    }

    private static func baseTraits(
        forceTouch: UIForceTouchCapability = .available
    ) -> UITraitCollection {
        UITraitCollection(traitsFrom: [
            .init(forceTouchCapability: forceTouch),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium),
            .init(userInterfaceIdiom: .phone),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular)
        ])
    }
}
