import Foundation

@available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
extension Snapshotting where Format == String {
  /// A snapshot strategy that captures a value's textual description from `String`'s
  /// `init(describing:)` initializer.
  ///
  /// ``` swift
  /// assertSnapshot(of: user, as: .description)
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// User(bio: "Blobbed around the world.", id: 1, name: "Blobby")
  /// ```
  public static var description: Snapshotting {
    return SimplySnapshotting.lines.pullback(String.init(describing:))
  }
}

@available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
extension Snapshotting where Format == String {
  /// A snapshot strategy for comparing any structure based on a sanitized text dump.
  ///
  /// The reference format looks a lot like the output of Swift's built-in `dump` function, though
  /// it does its best to make output deterministic by stripping out pointer memory addresses and
  /// sorting non-deterministic data, like dictionaries and sets.
  ///
  /// You can hook into how an instance of a type is rendered in this strategy by conforming to the
  /// ``AnySnapshotStringConvertible`` protocol and defining the
  /// ``AnySnapshotStringConvertible/snapshotDescription` property.
  ///
  /// ```swift
  /// assertSnapshot(of: user, as: .dump)
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// ▿ User
  ///   - bio: "Blobbed around the world."
  ///   - id: 1
  ///   - name: "Blobby"
  /// ```
  @available(
    iOS,
    deprecated: 9999,
    message: "Use '.customDump' from the 'SnapshotTestingCustomDump' module, instead."
  )
  @available(
    macOS,
    deprecated: 9999,
    message: "Use '.customDump' from the 'SnapshotTestingCustomDump' module, instead."
  )
  @available(
    tvOS,
    deprecated: 9999,
    message: "Use '.customDump' from the 'SnapshotTestingCustomDump' module, instead."
  )
  @available(
    watchOS,
    deprecated: 9999,
    message: "Use '.customDump' from the 'SnapshotTestingCustomDump' module, instead."
  )
  public static var dump: Snapshotting {
    return SimplySnapshotting.lines.pullback { snap($0) }
  }
}

@available(macOS 10.13, watchOS 4.0, tvOS 11.0, *)
@available(*, deprecated, message: "Migrate to the new SnapshotTesting API")
extension Snapshotting where Format == String {
  /// A snapshot strategy for comparing any structure based on their JSON representation.
  public static var json: Snapshotting {
    let options: JSONSerialization.WritingOptions = [
      .prettyPrinted,
      .sortedKeys,
    ]

    var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
      try! String(
        decoding: JSONSerialization.data(
          withJSONObject: data,
          options: options), as: UTF8.self)
    }
    snapshotting.pathExtension = "json"
    return snapshotting
  }
}

@available(*, deprecated)
private func snap<T>(
  _ value: T,
  name: String? = nil,
  indent: Int = 0,
  visitedValues: Set<ObjectIdentifier> = .init()
) -> String {
  let indentation = String(repeating: " ", count: indent)
  let mirror = Mirror(reflecting: value)
  var children = mirror.children
  let count = children.count
  let bullet = count == 0 ? "-" : "▿"
  var visitedValues = visitedValues

  let description: String
  switch (value, mirror.displayStyle) {
  case (_, .collection?):
    description = count == 1 ? "1 element" : "\(count) elements"
  case (_, .dictionary?):
    description = count == 1 ? "1 key/value pair" : "\(count) key/value pairs"
    children = sort(children, visitedValues: visitedValues)
  case (_, .set?):
    description = count == 1 ? "1 member" : "\(count) members"
    children = sort(children, visitedValues: visitedValues)
  case (_, .tuple?):
    description = count == 1 ? "(1 element)" : "(\(count) elements)"
  case (_, .optional?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).none" : "\(subjectType)"
  case (let value as AnySnapshotStringConvertible, _) where type(of: value).renderChildren:
    description = value.snapshotDescription
  case (let value as AnySnapshotStringConvertible, _):
    return "\(indentation)- \(name.map { "\($0): " } ?? "")\(value.snapshotDescription)\n"
  case (let value as CustomStringConvertible, _):
    description = value.description
  case (let value as AnyObject, .class?):
    let objectID = ObjectIdentifier(value)
    if visitedValues.contains(objectID) {
      return "\(indentation)\(bullet) \(name ?? "value") (circular reference detected)\n"
    }
    visitedValues.insert(objectID)
    description = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    children = sort(children, visitedValues: visitedValues)
  case (_, .struct?):
    description = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    children = sort(children, visitedValues: visitedValues)
  case (_, .enum?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).\(value)" : "\(subjectType)"
  case (let value, _):
    description = String(describing: value)
  }

  let lines =
    ["\(indentation)\(bullet) \(name.map { "\($0): " } ?? "")\(description)\n"]
    + children.map { snap($1, name: $0, indent: indent + 2, visitedValues: visitedValues) }

  return lines.joined()
}

@available(*, deprecated)
private func sort(_ children: Mirror.Children, visitedValues: Set<ObjectIdentifier>)
  -> Mirror.Children
{
  return .init(
    children
      .map({ (child: $0, snap: snap($0, visitedValues: visitedValues)) })
      .sorted(by: { $0.snap < $1.snap })
      .map({ $0.child })
  )
}

/// A type with a customized snapshot dump representation.
///
/// Types that conform to the `AnySnapshotStringConvertible` protocol can provide their own
/// representation to be used when converting an instance to a `dump`-based snapshot.
@available(*, deprecated)
public protocol AnySnapshotStringConvertible {
  /// Whether or not to dump child nodes (defaults to `false`).
  static var renderChildren: Bool { get }

  /// A textual snapshot dump representation of this instance.
  var snapshotDescription: String { get }
}

@available(*, deprecated)
extension AnySnapshotStringConvertible {
  public static var renderChildren: Bool {
    return false
  }
}

@available(*, deprecated)
extension Character: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

@available(*, deprecated)
extension Data: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

@available(*, deprecated)
extension Date: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return snapshotDateFormatter.string(from: self)
  }
}

@available(*, deprecated)
extension NSObject: AnySnapshotStringConvertible {
  #if canImport(ObjectiveC)
    @objc open var snapshotDescription: String {
      return purgePointers(self.debugDescription)
    }
  #else
    open var snapshotDescription: String {
      return purgePointers(self.debugDescription)
    }
  #endif
}

@available(*, deprecated)
extension String: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

@available(*, deprecated)
extension Substring: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

@available(*, deprecated)
extension URL: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

private let snapshotDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(abbreviation: "UTC")
  return formatter
}()

func purgePointers(_ string: String) -> String {
  return string.replacingOccurrences(
    of: ":?\\s*0x[\\da-f]+(\\s*)", with: "$1", options: .regularExpression)
}
