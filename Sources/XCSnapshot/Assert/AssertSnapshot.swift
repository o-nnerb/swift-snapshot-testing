import XCTest

// MARK: - Assert snapshot

/// Valida um snapshot único de um valor de entrada usando uma configuração específica.
///
/// - Parameters:
///   - input: Valor de entrada a ser serializado e comparado com o snapshot armazenado.
///   - configuration: Configuração que define como o snapshot é gerado (ex: layout, precisão de imagem).
///   - serialization: Configuração de serialização para controlar detalhes como escalonamento.
///   - name: Nome opcional para identificar o snapshot (útil em testes com múltiplos snapshots).
///   - recording: Modo de gravação override para este teste (ex: `.always` para forçar atualização).
///   - fileID, filePath, testName, line, column: Parâmetros internos para localização do teste.
///
/// - WARNING: A contagem automática dos snapshots em um único teste é com base na posição em que a
///   função `assertSnapshot` é chamada. Caso esteja fazendo um for-loop, considere configurar o parâmetro
///   `name`.
///
/// Observações:
///   - Se `recording` não for definido, usa o valor global de `TestingSession.shared.record`, ou do Testing Traits ou quando encapsulado por `withSnapshotTesting(record:operation:)`.
///
/// Exemplo:
///   ```swift
///   try await assertSnapshot(of: myView, as: .image(layout: .iPhone15ProMax), named: "dark_mode")
///   ```
public func assertSnapshot<Input: Sendable, Output: BytesRepresentable> (
    of input: @autoclosure @Sendable () async throws -> Input,
    as configuration: SnapshotConfiguration<Input, Output>,
    serialization: DataSerialization = DataSerialization(),
    named name: String? = nil,
    record recording: RecordMode? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    let failure = try await SnapshotVerifier.verify(
        input: input(),
        configuration: configuration,
        serialization: serialization,
        named: name,
        record: recording,
        snapshotDirectory: nil,
        fileID: fileID,
        filePath: filePath,
        testName: testName,
        line: line,
        column: column
    )
    guard let message = failure else { return }

    _TestingFramework.shared.record(
        message: message,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

/// Valida múltiplos snapshots de um valor de entrada usando várias configurações nomeadas.
///
/// - Parameters:
///   - input: Valor de entrada comum a todos os snapshots.
///   - strategies: Dicionário de configurações nomeadas (chave = nome do snapshot).
///   - serialization: Configuração de serialização compartilhada para todos os snapshots.
///   - recording: Modo de gravação override para todos os snapshots.
///   - fileID, filePath, testName, line, column: Parâmetros internos para localização do teste.
///
/// - WARNING: A contagem automática dos snapshots em um único teste é com base na posição em que a
///   função `assertSnapshot` é chamada. Caso esteja fazendo um for-loop, considere configurar o parâmetro
///   `name`.
///
/// Observações:
///   - Executa todos os snapshots em sequência, usando cada configuração do dicionário.
///   - Cada chave do dicionário `strategies` se torna o nome do snapshot.
///   - Útil para testar o mesmo input com diferentes layouts ou precisões.
///
/// Exemplo:
///   ```swift
///   let strategies: [String: SnapshotConfiguration] = [
///       "portrait": .image(layout: .iPhone15ProMax),
///       "landscape": .image(layout: .iPhone15ProMax(.init(traits: .landscape)))
///   ]
///   try await assertSnapshots(myView, as: strategies)
///   ```
public func assertSnapshots<Input: Sendable, Output: BytesRepresentable>(
    of input: @autoclosure @Sendable () async throws -> Input,
    as strategies: [String: SnapshotConfiguration<Input, Output>],
    serialization: DataSerialization = DataSerialization(),
    record recording: RecordMode? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    for (name, configuration) in strategies {
        try? await assertSnapshot(
            of: await input(),
            as: configuration,
            serialization: serialization,
            named: name,
            record: recording,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

/// Valida múltiplos snapshots de um valor de entrada usando várias configurações.
///
/// - Parameters:
///   - input: Valor de entrada comum a todos os snapshots.
///   - strategies: Array de configurações para cada snapshot.
///   - serialization: Configuração de serialização compartilhada.
///   - recording: Modo de gravação override para todos os snapshots.
///   - fileID, filePath, testName, line, column: Parâmetros internos para localização do teste.
///
/// - WARNING: A contagem automática dos snapshots em um único teste é com base na posição em que a
///   função `assertSnapshot` é chamada. Caso esteja fazendo um for-loop, considere configurar o parâmetro
///   `name`.
///
/// - Observações:
///   - Diferente da versão com dicionário, não usa nomes explícitos para cada snapshot.
///   - Recomenda-se usar o dicionário quando nomes significativos forem necessários.
///   - Útil para testes com configurações similares que não exigem identificação individual.
///
/// Exemplo:
///   ```swift
///   let strategies = [
///       .image(layout: .iPhone15ProMax),
///       .image(precision: 0.95)
///   ]
///   try await assertSnapshots(myView, as: strategies)
///   ```
public func assertSnapshots<Input: Sendable, Output: BytesRepresentable>(
    of input: @autoclosure @Sendable () async throws -> Input,
    as strategies: [SnapshotConfiguration<Input, Output>],
    serialization: DataSerialization = DataSerialization(),
    record recording: RecordMode? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    for strategy in strategies {
        try? await assertSnapshot(
            of: await input(),
            as: strategy,
            serialization: serialization,
            record: recording,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}
