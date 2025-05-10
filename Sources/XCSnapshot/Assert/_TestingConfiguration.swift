import Foundation

/// Configura temporariamente as opções de teste de snapshot para um bloco de código específico.
///
/// Essa função permite definir valores locais para `record` e `diffTool` que substituem as configurações
/// globais de `TestingSession.shared` durante a execução do `operation`. Após a conclusão do bloco,
/// as configurações originais são restauradas.
///
/// - Parameters:
///   - record: Modo de gravação override para este bloco (ex: `.always` para forçar atualização de snapshots).
///   - diffTool: Ferramenta de comparação override para este bloco (ex: `.ksdiff` para usar o Kaleidoscope).
///   - maxConcurrentTests: Limite máximo de testes simultâneos durante o bloco (substitui
///   `TestingSession.shared.maxConcurrentTests`).
///   - operation: Bloco de código a ser executado com as configurações temporárias.
///
/// - Returns: O valor de retorno do `operation`.
///
/// - Observações:
///   - Útil para testes isolados que requerem configurações diferentes do padrão global.
///   - Não interfere nas configurações globais de `SnapshotSession` fora do escopo do bloco.
///
/// - Exemplo:
///   ```swift
///   withSnapshotTesting(record: .always) {
///       assertSnapshot(myView, as: .image()) // Grava o snapshot mesmo se já existir
///   }
///   ```
public func withSnapshotTesting<R>(
    record: RecordMode? = nil,
    diffTool: DiffTool? = nil,
    maxConcurrentTests: Int? = nil,
    operation: () -> R
) -> R {
    _TestingConfiguration.$current.withValue(
        _TestingConfiguration(
            record: record,
            diffTool: diffTool,
            maxConcurrentTests: maxConcurrentTests
        ),
        operation: operation
    )
}

/// Versão assíncrona e que pode lançar erros da função `withSnapshotTesting`.
///
/// Permite executar operações assíncronas com configurações de snapshot temporárias.
///
/// - Parameters:
///   - record: Modo de gravação override para este bloco.
///   - diffTool: Ferramenta de comparação override para este bloco.
///   - maxConcurrentTests: Limite máximo de testes simultâneos durante o bloco (substitui
///   `TestingSession.shared.maxConcurrentTests`).
///   - operation: Bloco assíncrono a ser executado com as configurações temporárias.
///
/// - Returns: O valor de retorno do `operation`.
///
/// - Observações:
///   - Usa `rethrows` para propagar erros do `operation`.
///   - Útil para testes que envolvem operações assíncronas (ex: acesso a APIs ou processamento de dados).
///
/// - Exemplo:
///   ```swift
///   try await withSnapshotTesting(diffTool: .ksdiff) {
///       await assertSnapshot(myAsyncView(), as: .image())
///   }
///   ```
public func withSnapshotTesting<R>(
    record: RecordMode? = nil,
    diffTool: DiffTool? = nil,
    maxConcurrentTests: Int? = nil,
    operation: @Sendable () async throws -> R
) async rethrows -> R {
    try await _TestingConfiguration.$current.withValue(
        _TestingConfiguration(
            record: record,
            diffTool: diffTool,
            maxConcurrentTests: maxConcurrentTests
        ),
        operation: operation
    )
}

public struct _TestingConfiguration: Sendable {

    @TaskLocal static var current: Self?

    public private(set) var diffTool: DiffTool?
    public private(set) var record: RecordMode?
    public private(set) var maxConcurrentTests: Int?

    public init(
        record: RecordMode?,
        diffTool: DiffTool?,
        maxConcurrentTests: Int?
    ) {
        self.diffTool = diffTool
        self.record = record
        self.maxConcurrentTests = maxConcurrentTests
    }

    public static func + (_ lhs: Self, _ rhs: Self) -> Self {
        var lhs = lhs

        if lhs.diffTool == nil, let diffTool = rhs.diffTool {
            lhs.diffTool = diffTool
        }

        if lhs.record == nil, let record = rhs.record {
            lhs.record = record
        }

        if lhs.maxConcurrentTests == nil, let maxConcurrentTests = rhs.maxConcurrentTests {
            lhs.maxConcurrentTests = maxConcurrentTests
        }

        return lhs
    }
}
