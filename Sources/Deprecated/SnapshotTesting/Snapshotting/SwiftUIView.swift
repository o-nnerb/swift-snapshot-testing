#if canImport(SwiftUI)
  import Foundation
  import SwiftUI

  /// The size constraint for a snapshot (similar to `PreviewLayout`).
  @available(*, deprecated, renamed: "LayoutConfiguration")
  public enum SwiftUISnapshotLayout {
    #if os(iOS) || os(tvOS)
      /// Center the view in a device container described by`config`.
      case device(config: ViewImageConfig)
    #endif
    /// Center the view in a fixed size container.
    case fixed(width: CGFloat, height: CGFloat)
    /// Fit the view to the ideal size that fits its content.
    case sizeThatFits
  }

  #if os(iOS) || os(tvOS)
    @available(iOS 13.0, tvOS 13.0, *)
    @available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
    extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

      /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
      public static var image: Snapshotting {
        return .image()
      }

      /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
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
      ///   - layout: A view layout override.
      ///   - traits: A trait collection override.
      public static func image(
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init()
      )
        -> Snapshotting
      {
        let config: ViewImageConfig

        switch layout {
        #if os(iOS) || os(tvOS)
          case .device(config: let deviceConfig):
            config = deviceConfig
        #endif
        case .sizeThatFits:
          config = .init(safeArea: .zero, size: nil, traits: traits)
        case .fixed(let width, let height):
          let size = CGSize(width: width, height: height)
          config = .init(safeArea: .zero, size: size, traits: traits)
        }

        return SimplySnapshotting.image(
          precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale
        ).asyncPullback { view in
          var config = config

          let controller: UIViewController

          if config.size != nil {
            controller = UIHostingController.init(
              rootView: view
            )
          } else {
            let hostingController = UIHostingController.init(rootView: view)

            let maxSize = CGSize(width: 0.0, height: 0.0)
            config.size = hostingController.sizeThatFits(in: maxSize)

            controller = hostingController
          }

          return snapshotView(
            config: config,
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            traits: traits,
            view: controller.view,
            viewController: controller
          )
        }
      }
    }
  #endif
#endif
