@_exported import XCSnapshot
import Testing

extension _TestingFramework: _SwiftTestingFramework {

    public var testingConfiguration: _TestingConfiguration? {
        Test.current?.traits.mergingTestingConfiguration()
    }

    public func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        Issue.record(
            Comment(rawValue: message),
            sourceLocation: SourceLocation(
                fileID: String(fileID),
                filePath: String(filePath),
                line: Int(line),
                column: Int(column)
            )
        )
    }
}

extension Array where Element == any Trait {

    func mergingTestingConfiguration() -> _TestingConfiguration {
        var testingConfiguration = _TestingConfiguration(
            record: nil,
            diffTool: nil,
            maxConcurrentTests: nil
        )

        for trait in reversed() {
            guard let snapshotTrait = trait as? _SnapshotsTestTrait else {
                continue
            }

            testingConfiguration = testingConfiguration + snapshotTrait.configuration

            guard
                testingConfiguration.diffTool != nil,
                testingConfiguration.record != nil,
                testingConfiguration.maxConcurrentTests != nil
            else { continue }

            break
        }

        return testingConfiguration
    }
}
