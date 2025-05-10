import Foundation
import XCTest
import UniformTypeIdentifiers
import CoreServices

struct SnapshotVerifier<Input: Sendable, Output: BytesRepresentable>: Sendable where Output: BytesRepresentable {

    // MARK: - Private properties

    private let input: Input
    private let configuration: SnapshotConfiguration<Input, Output>
    private let serialization: DataSerialization
    private let name: String?
    private let recording: RecordMode?
    private let snapshotDirectory: String?
    private let fileID: StaticString
    private let filePath: StaticString
    private let testName: String
    private let line: UInt
    private let column: UInt

    // MARK: - Inits

    private init(
        input: Input,
        configuration: SnapshotConfiguration<Input, Output>,
        serialization: DataSerialization,
        named name: String?,
        record recording: RecordMode?,
        snapshotDirectory: String?,
        fileID: StaticString,
        filePath: StaticString,
        testName: String,
        line: UInt,
        column: UInt
    ) {
        self.input = input
        self.configuration = configuration
        self.serialization = serialization
        self.name = name
        self.recording = recording
        self.snapshotDirectory = snapshotDirectory
        self.fileID = fileID
        self.filePath = filePath
        self.testName = testName
        self.line = line
        self.column = column
    }

    // MARK: - Internal methods

    static func verify(
        input: Input,
        configuration: SnapshotConfiguration<Input, Output>,
        serialization: DataSerialization,
        named name: String?,
        record recording: RecordMode?,
        snapshotDirectory: String?,
        fileID: StaticString,
        filePath: StaticString,
        testName: String,
        line: UInt,
        column: UInt
    ) async throws -> String? {
        let verifier = SnapshotVerifier(
            input: input,
            configuration: configuration,
            serialization: serialization,
            named: name,
            record: recording,
            snapshotDirectory: snapshotDirectory,
            fileID: fileID,
            filePath: filePath,
            testName: testName,
            line: line,
            column: column
        )

        return try await verifier()
    }

    // MARK: - Private methods

    private func callAsFunction() async throws -> String? {
        // 2. Determinar modo de gravação
        let recordMode = resolveRecordMode()

        // 3. Gerenciar contexto de snapshot
        return try await withSnapshotTesting(record: recordMode) {
            try await assert(recordMode: recordMode)
        }
    }

    private func assert(
        recordMode: RecordMode
    ) async throws -> String? {
        // 1. Configurar diretórios e URLs
        let fileManager = SnapshotFileManager(
            filePath: filePath,
            snapshotDirectory: snapshotDirectory
        )
        let directoryURL = try fileManager.setupDirectories()
        let testNameSanitized = Tools.sanitizePathComponent(testName)

        // 2. Gerar identificador único
        let identifier = name.map { Tools.sanitizePathComponent($0) } ?? String(
            FileCounter.shared.identifier(
                fileID: fileID,
                filePath: filePath,
                testName: testName,
                line: line,
                column: column
            )
        )

        // 3. Construir URL do snapshot
        let snapshotURL = fileManager.generateSnapshotURL(
            directoryURL: directoryURL,
            pathExtension: configuration.pathExtension,
            testName: testNameSanitized,
            identifier: identifier
        )

        // 4. Processar entrada para obter o diffable
        let diffable = try await configuration.pipeline(input)

        // 5. Lógica condicional de gravação/comparação
        if recordMode == .always {
            // Modo de gravação ativo
            return try await handleRecordingModeAll(
                snapshotURL: snapshotURL,
                diffable: diffable
            )
        } else {
            // Modo de comparação
            return try await handleComparisonMode(
                snapshotURL: snapshotURL,
                diffable: diffable,
                recordMode: recordMode
            )
        }
    }

    // MARK: - Métodos Auxiliares
    private func resolveRecordMode() -> RecordMode {
        // Determina o modo de gravação com base nos parâmetros e configurações
        if let recording = recording {
            return recording
        }

        return TestingSession.shared.record
    }

    private func handleRecordingModeAll(
        snapshotURL: URL,
        diffable: Output
    ) async throws -> String {
        try await recordSnapshot(
            diffable: diffable,
            snapshotURL: snapshotURL,
            writeToDisk: true
        )

        return """
        Record mode is on. Automatically recorded snapshot:
        
        open "\(snapshotURL.absoluteString)"
        
        Turn record mode off and re-run "\(testName)" to assert against the newly-recorded snapshot
        """
    }

    private func handleComparisonMode(
        snapshotURL: URL,
        diffable: Output,
        recordMode: RecordMode
    ) async throws -> String? {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: snapshotURL.path) {
            return try await handleMissingSnapshot(
                snapshotURL: snapshotURL,
                diffable: diffable,
                recordMode: recordMode
            )
        } else {
            return try await handleExistingSnapshot(
                snapshotURL: snapshotURL,
                diffable: diffable
            )
        }
    }

    private func handleMissingSnapshot(
        snapshotURL: URL,
        diffable: Output,
        recordMode: RecordMode
    ) async throws -> String {
        let shouldWrite = recordMode != .never
        try await recordSnapshot(
            diffable: diffable,
            snapshotURL: snapshotURL,
            writeToDisk: shouldWrite
        )

        if shouldWrite {
            return """
            No reference was found on disk. Automatically recorded snapshot:
            
            open "\(snapshotURL.absoluteString)"
            
            Re-run "\(testName)" to assert against the newly-recorded snapshot.
            """
        } else {
            return "New snapshot was not recorded because recording is disabled"
        }
    }

    private func handleExistingSnapshot(
        snapshotURL: URL,
        diffable: Output
    ) async throws -> String? {
        let referenceData = try Data(contentsOf: snapshotURL)
        let reference = try serialization.deserialize(Output.self, from: referenceData)

        // Gerar anexos e mensagem de erro
        guard let messageAttachment = await configuration.attachmentGenerator(
            from: reference,
            with: diffable
        ) else { return nil }

        // Salvar snapshot falhado em artifacts
        let artifactsURL = Tools.generateArtifactsURL(
            filePath: filePath
        )
        try FileManager.default.createDirectory(
            at: artifactsURL,
            withIntermediateDirectories: true
        )
        let failedURL = artifactsURL.appendingPathComponent(snapshotURL.lastPathComponent)
        try serialization.serialize(diffable).write(to: failedURL)

        // Adicionar anexos ao contexto de teste
        await Tools.addAttachments(messageAttachment.attachments, named: "Attached Failure Diff")

        // Gerar mensagem final
        let diffMessage = TestingSession.shared.diffTool(
            currentFilePath: snapshotURL.absoluteString,
            failedFilePath: failedURL.absoluteString
        )

        let failureMessage: String
        if let name = self.name {
            failureMessage = "Snapshot \"\(name)\" does not match reference."
        } else {
            failureMessage = "Snapshot does not match reference."
        }

        let failureMessageWithDetails = """
        \(failureMessage)
        
        \(diffMessage)
        
        \(messageAttachment.message.trimmingCharacters(in: .whitespacesAndNewlines))
        """

        return failureMessageWithDetails
    }

    // MARK: - Operações de Gravação
    private func recordSnapshot(
        diffable: Output,
        snapshotURL: URL,
        writeToDisk: Bool
    ) async throws {
        let snapshotData = try serialization.serialize(diffable)

        if writeToDisk {
            try snapshotData.write(to: snapshotURL)
        }

        // Adicionar anexo ao contexto de teste
        if !_TestingFramework.shared.isSwiftTesting && ProcessInfo.isXcode {
            await Tools.addSnapshotAttachment(
                snapshotData: snapshotData,
                snapshotURL: snapshotURL,
                pathExtension: configuration.pathExtension,
                writeToDisk: writeToDisk
            )
        }
    }

    // MARK: - Utilitários
}

private extension SnapshotVerifier {

    enum Tools {
        @MainActor
        static func addAttachments(_ attachments: [XCTAttachment], named: String) {
            if !_TestingFramework.shared.isSwiftTesting && ProcessInfo.isXcode {
                XCTContext.runActivity(named: named) { activity in
                    attachments.forEach { activity.add($0) }
                }
            }
        }

        static func addSnapshotAttachment(
            snapshotData: Data,
            snapshotURL: URL,
            pathExtension: String?,
            writeToDisk: Bool
        ) async {
            let named = "Attached Recorded Snapshot"

            if writeToDisk {
                let attachment = XCTAttachment(contentsOfFile: snapshotURL)
                await Self.addAttachments([attachment], named: named)
            } else {
                let typeIdentifier = pathExtension.flatMap {
                    if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                        return UTType(filenameExtension: $0)?.identifier
                    } else {
                        let unmanagedString = UTTypeCreatePreferredIdentifierForTag(
                            kUTTagClassFilenameExtension as CFString,
                            $0 as CFString,
                            nil
                        )

                        return unmanagedString?.takeRetainedValue() as String?
                    }
                }

                let attachment = XCTAttachment(
                    uniformTypeIdentifier: typeIdentifier ?? "",
                    name: snapshotURL.lastPathComponent,
                    payload: snapshotData
                )
                await Self.addAttachments([attachment], named: named)
            }
        }

        static func generateArtifactsURL(
            filePath: StaticString
        ) -> URL {
            let filePath = filePath.withUTF8Buffer {
                String(decoding: $0, as: UTF8.self)
            }
            let artifactsDir = ProcessInfo.artifactsDirectory
            return artifactsDir
                .appendingPathComponent(
                    URL(
                        fileURLWithPath: filePath,
                        isDirectory: false
                    )
                    .deletingPathExtension()
                    .lastPathComponent
                )
        }

        static func sanitizePathComponent(_ path: String) -> String {
            return path.replacingOccurrences(
                of: "[^a-zA-Z0-9_]",
                with: "_",
                options: .regularExpression
            )
            .trimmingCharacters(in: .init(charactersIn: "_"))
        }
    }
}
