#if os(iOS) || os(tvOS)
  import UIKit

  @available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
  extension Snapshotting where Value == UIViewController, Format == UIImage {
    /// A snapshot strategy for comparing view controller views based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing view controller views based on pixel equality.
    ///
    /// - Parameters:
    ///   - config: A set of device configuration settings.
    ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render
    ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your
    ///     tests and will _not_ work for framework test targets.
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - size: A view size override.
    ///   - traits: A trait collection override.
    public static func image(
      on config: ViewImageConfig,
      drawHierarchyInKeyWindow: Bool = false,
      precision: Float = 1,
      perceptualPrecision: Float = 1,
      size: CGSize? = nil,
      traits: UITraitCollection = .init()
    )
      -> Snapshotting
    {

      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale
      ).asyncPullback { viewController in
        snapshotView(
          config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) }
            ?? config,
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
      }
    }

    /// A snapshot strategy for comparing view controller views based on pixel equality.
    ///
    /// - Parameters:
    ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render
    ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your
    ///     tests and will _not_ work for framework test targets.
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - size: A view size override.
    ///   - traits: A trait collection override.
    public static func image(
      drawHierarchyInKeyWindow: Bool = false,
      precision: Float = 1,
      perceptualPrecision: Float = 1,
      size: CGSize? = nil,
      traits: UITraitCollection = .init()
    )
      -> Snapshotting
    {

      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale
      ).asyncPullback { viewController in
        snapshotView(
          config: .init(safeArea: .zero, size: size, traits: traits),
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
      }
    }
  }

  @available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
  extension Snapshotting where Value == UIViewController, Format == String {
    /// A snapshot strategy for comparing view controllers based on their embedded controller
    /// hierarchy.
    ///
    /// ``` swift
    /// assertSnapshot(of: vc, as: .hierarchy)
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// <UITabBarController>, state: appeared, view: <UILayoutContainerView>
    ///    | <UINavigationController>, state: appeared, view: <UILayoutContainerView>
    ///    |    | <UIPageViewController>, state: appeared, view: <_UIPageViewControllerContentView>
    ///    |    |    | <UIViewController>, state: appeared, view: <UIView>
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    /// ```
    public static var hierarchy: Snapshotting {
      return Snapshotting<String, String>.lines.pullback { viewController in
        let dispose = prepareView(
          config: .init(),
          drawHierarchyInKeyWindow: false,
          traits: .init(),
          view: viewController.view,
          viewController: viewController
        )
        defer { dispose() }
        return purgePointers(
          viewController.perform(Selector(("_printHierarchy"))).retain().takeUnretainedValue()
            as! String
        )
      }
    }

    /// A snapshot strategy for comparing view controller views based on a recursive description of
    /// their properties and hierarchies.
    public static var recursiveDescription: Snapshotting {
      return Snapshotting.recursiveDescription()
    }

    /// A snapshot strategy for comparing view controller views based on a recursive description of
    /// their properties and hierarchies.
    ///
    /// - Parameters:
    ///   - config: A set of device configuration settings.
    ///   - size: A view size override.
    ///   - traits: A trait collection override.
    public static func recursiveDescription(
      on config: ViewImageConfig = .init(),
      size: CGSize? = nil,
      traits: UITraitCollection = .init()
    )
      -> Snapshotting<UIViewController, String>
    {
      return SimplySnapshotting.lines.pullback { viewController in
        let dispose = prepareView(
          config: .init(
            safeArea: config.safeArea, size: size ?? config.size, traits: config.traits),
          drawHierarchyInKeyWindow: false,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
        defer { dispose() }
        return purgePointers(
          viewController.view.perform(Selector(("recursiveDescription"))).retain()
            .takeUnretainedValue()
            as! String
        )
      }
    }
  }
#endif
