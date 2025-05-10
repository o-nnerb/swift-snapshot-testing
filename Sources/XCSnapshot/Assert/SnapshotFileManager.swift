import Foundation

struct SnapshotFileManager: Sendable {

    // MARK: - Private properties

    private let fileUrl: URL
    private let snapshotDirectoryPath: String?

    // MARK: - Inits
    
    init(
        filePath: StaticString,
        snapshotDirectory: String?
    ) {
        let filePath = filePath.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
        self.fileUrl = URL(fileURLWithPath: filePath, isDirectory: false)
        self.snapshotDirectoryPath = snapshotDirectory
    }

    // MARK: - Internal methods
    
    func setupDirectories() throws -> URL {
        let snapshotsBaseURL = fileUrl.deletingLastPathComponent()
        
        let directoryURL: URL
        if let customDir = snapshotDirectoryPath {
            directoryURL = URL(fileURLWithPath: customDir, isDirectory: true)
        } else {
            let fileName = fileUrl.deletingPathExtension().lastPathComponent
            directoryURL = snapshotsBaseURL
                .appendingPathComponent("__Snapshots__")
                .appendingPathComponent(fileName)
        }
        
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        
        return directoryURL
    }
    
    func generateSnapshotURL(
        directoryURL: URL,
        pathExtension: String?,
        testName: String,
        identifier: String
    ) -> URL {
        var snapshotURL = directoryURL
            .appendingPathComponent("\(testName).\(identifier)")
        
        if let pathExtension {
            snapshotURL.appendPathExtension(pathExtension)
        }
        
        return snapshotURL
    }
}
