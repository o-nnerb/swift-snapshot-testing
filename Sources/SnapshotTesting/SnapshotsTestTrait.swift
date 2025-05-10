import Testing

/// Define configurações globais para testes de snapshot em um contexto de suíte ou teste.
///
/// O `_SnapshotsTestTrait` permite aplicar configurações como modo de gravação (`record`) e ferramenta de
/// comparação (`diffTool`) para uma suíte de testes ou teste individual. Isso facilita a reutilização de configurações
/// em múltiplos testes sem repetições.
public struct _SnapshotsTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: _TestingConfiguration
}

extension Trait where Self == _SnapshotsTestTrait {

    /// Trait padrão para testes de snapshot usando as configurações globais.
    ///
    /// Configura os valores de `TestingSession.shared.record`, `TestingSession.shared.diffTool`
    /// e `TestingSession.shared.maxConcurrentTests` como padrão.
    public static var snapshots: Self {
        snapshots()
    }

    /// Cria um trait personalizado para testes de snapshot com configurações específicas.
    ///
    /// - Parameters:
    ///   - record: Modo de gravação override para o teste/suíte (ex: `.always` para forçar atualização de
    ///   snapshots).
    ///   - maxConcurrentTests: Limite máximo de testes simultâneos para o teste/suíte (substitui
    ///   `TestingSession.shared.maxConcurrentTests`).
    ///   - diffTool: Ferramenta de comparação override (ex: `.ksdiff` para usar o Kaleidoscope).
    ///
    /// - Returns: Um trait com as configurações fornecidas, substituindo temporariamente as globais.
    ///
    /// Exemplos de uso:
    ///   ```swift
    ///   // Aplica modo de gravação "always" para uma suíte
    ///   @TestSuite(.snapshots(record: .always, maxConcurrentTests: 5))
    ///   struct MyTests {}
    ///
    ///   // Define ferramenta de diff para um teste individual
    ///   @Test(.snapshots(diffTool: "opendiff"))
    ///   func testExample() { ... }
    ///   ```
    public static func snapshots(
        record: RecordMode? = nil,
        diffTool: DiffTool? = nil,
        maxConcurrentTests: Int? = nil
    ) -> Self {
        _SnapshotsTestTrait(
            configuration: _TestingConfiguration(
                record: record,
                diffTool: diffTool,
                maxConcurrentTests: maxConcurrentTests
            )
        )
    }
}
