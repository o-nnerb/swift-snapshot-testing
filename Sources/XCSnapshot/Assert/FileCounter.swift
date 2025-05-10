import Foundation

class FileCounter: @unchecked Sendable {

    static let shared = FileCounter()

    private let lock = NSLock()
    
    private var _table: [TestingMethod: [TestingMethod.Unit]] = [:]

    private init() {}

    func identifier(
        fileID: StaticString,
        filePath: StaticString,
        testName: String,
        line: UInt,
        column: UInt
    ) -> Int {
        lock.withLock {
            let key = TestingMethod(
                fileID: fileID,
                filePath: filePath,
                testName: testName
            )

            let unit = TestingMethod.Unit(
                line: line,
                column: column
            )

            return _table[key, default: []].appendOrdered(unit)
        } + 1
    }
}

struct TestingMethod: Hashable {

    struct Unit: Hashable {

        private let line: UInt
        private let column: UInt

        init(
            line: UInt,
            column: UInt
        ) {
            self.line = line
            self.column = column
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.line < rhs.line || (lhs.line == rhs.line && lhs.column < rhs.column)
        }

        static func > (lhs: Self, rhs: Self) -> Bool {
            lhs.line > rhs.line || (lhs.line == rhs.line && lhs.column > rhs.column)
        }
    }

    private let fileID: String
    private let filePath: String
    private let testName: String

    init(
        fileID: StaticString,
        filePath: StaticString,
        testName: String
    ) {
        self.fileID = fileID.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
        self.filePath = filePath.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
        self.testName = testName
    }
}

private extension Array<TestingMethod.Unit> {

    mutating func appendOrdered(_ unit: Element) -> Int {
        if isEmpty {
            append(unit)
            return .zero
        }

        var index = startIndex
        while index < endIndex {
            defer { index += 1 }

            if self[index] == unit {
                return index
            }

            if self[index] > unit {
                insert(unit, at: index)
                return index
            }
        }

        append(unit)
        return index
    }
}
