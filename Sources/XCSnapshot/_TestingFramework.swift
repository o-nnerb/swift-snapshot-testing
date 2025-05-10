import XCTest

public protocol _SwiftTestingFramework {

    var testingConfiguration: _TestingConfiguration? { get }

    func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    )
}

public final class _TestingFramework: Sendable {
    public static let shared = _TestingFramework()

    var isSwiftTesting: Bool {
        self is _SwiftTestingFramework
    }

    var testingConfiguration: _TestingConfiguration? {
        if let swiftTestingFramework = self as? _SwiftTestingFramework {
            return swiftTestingFramework.testingConfiguration
        } else {
            return nil
        }
    }

    func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        if let swiftTestingFramework = self as? _SwiftTestingFramework {
            swiftTestingFramework.record(
                message: message,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        } else {
            XCTFail(message, file: filePath, line: line)
        }
    }
}
