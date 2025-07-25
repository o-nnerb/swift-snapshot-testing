#if os(macOS)
  import AppKit
  import Cocoa

  @available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
  extension Snapshotting where Value == NSView, Format == NSImage {
    /// A snapshot strategy for comparing views based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing views based on pixel equality.
    ///
    /// > Note: Snapshots must be compared on the same OS as the device that originally took the
    /// > reference to avoid discrepancies between images.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - size: A view size override.
    public static func image(
      precision: Float = 1, perceptualPrecision: Float = 1, size: CGSize? = nil
    ) -> Snapshotting {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision
      ).asyncPullback { view in
        let initialSize = view.frame.size
        if let size = size { view.frame.size = size }
        guard view.frame.width > 0, view.frame.height > 0 else {
          fatalError("View not renderable to image at size \(view.frame.size)")
        }
        return view.snapshot
          ?? Async { callback in
            addImagesForRenderedViews(view).sequence().run { views in
              let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
              view.cacheDisplay(in: view.bounds, to: bitmapRep)
              let image = NSImage(size: view.bounds.size)
              image.addRepresentation(bitmapRep)
              callback(image)
              views.forEach { $0.removeFromSuperview() }
              view.frame.size = initialSize
            }
          }
      }
    }
  }

  @available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
  extension Snapshotting where Value == NSView, Format == String {
    /// A snapshot strategy for comparing views based on a recursive description of their properties
    /// and hierarchies.
    ///
    /// ``` swift
    /// assertSnapshot(of: view, as: .recursiveDescription)
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// [   AF      LU ] h=--- v=--- NSButton "Push Me" f=(0,0,77,32) b=(-)
    ///   [   A       LU ] h=--- v=--- NSButtonBezelView f=(0,0,77,32) b=(-)
    ///   [   AF      LU ] h=--- v=--- NSButtonTextField "Push Me" f=(10,6,57,16) b=(-)
    /// ```
    public static var recursiveDescription: Snapshotting<NSView, String> {
      return SimplySnapshotting.lines.pullback { view in
        return purgePointers(
          view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
            as! String
        )
      }
    }
  }
#endif
