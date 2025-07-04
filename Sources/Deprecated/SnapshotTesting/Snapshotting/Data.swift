import Foundation
import XCTest

@available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
extension Snapshotting where Value == Data, Format == Data {
  /// A snapshot strategy for comparing bare binary data.
  public static var data: Snapshotting {
    return .init(
      pathExtension: nil,
      diffing: .init(toData: { $0 }, fromData: { $0 }) { old, new in
        guard old != new else { return nil }
        let message =
          old.count == new.count
          ? "Expected data to match"
          : "Expected \(new) to match \(old)"
        return (message, [])
      }
    )
  }
}
