import Foundation
import XCTest

/// The ability to compare `Value`s and convert them to and from `Data`.
@available(*, deprecated, renamed: "DiffAttachmentGenerator")
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) -> Value

  /// Compares two values. If the values do not match, returns a failure message and artifacts
  /// describing the failure.
  public var diff: (Value, Value) -> (String, [XCTAttachment])?

  /// Creates a new `Diffing` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data.
  ///   - fromData: A function used to produce a value _from_ data.
  ///   - diff: A function used to compare two values. If the values do not match, returns a failure
  public init(
    toData: @escaping (_ value: Value) -> Data,
    fromData: @escaping (_ data: Data) -> Value,
    diff: @escaping (_ lhs: Value, _ rhs: Value) -> (String, [XCTAttachment])?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diff = diff
  }
}
