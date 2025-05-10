import Foundation
import Testing

/// Gerenciador global de configurações para testes de snapshot.
///
/// A `SnapshotSession` fornece configurações globais que afetam todos os testes de snapshot executados no
/// ambiente. Isso inclui:
/// 
/// - A ferramenta de comparação de diferenças (`diffTool`).
/// - O modo de gravação de snapshots (`record`).
/// - O limite máximo de testes simultâneos (`maxConcurrentTests`).
///
/// - NOTE: A instância `shared` é usada como ponto único de configuração para toda a sessão de testes.
public final class TestingSession: @unchecked Sendable {

    /// Instância global única para configurar opções de snapshot.
    ///
    /// Use esta propriedade para definir configurações como a ferramenta de diff padrão ou o modo de gravação.
    ///
    /// - Exemplo:
    ///   ```swift
    ///   TestingSession.shared.diffTool = .ksdiff
    ///   TestingSession.shared.record = .missing
    ///   ```
    public static let shared = TestingSession()

    // MARK: - Public properties

    /// Ferramenta padrão usada para exibir diferenças entre snapshots.
    ///
    /// - Padrão: `DiffTool.default`.
    ///
    /// Exemplos:
    ///   - `.ksdiff`: Usa o [Kaleidoscope](http://kaleidoscope.app) para comparar visualmente.
    ///   - Uma string como `"opendiff"` para comandos customizados.
    public var diffTool: DiffTool {
        set { lock.withLock { _diffTool = newValue } }
        get {
            // 1. Trait
            if let diffTool = _TestingFramework.shared.testingConfiguration?.diffTool {
                return diffTool
            }
            // 2. withConfiguration
            if let diffTool = _TestingConfiguration.current?.diffTool {
                return diffTool
            }
            // 3. shared
            return lock.withLock { _diffTool }
        }
    }

    /// Modo de gravação padrão para todos os snapshots.
    ///
    /// Padrão: `.missing` (grava novos snapshots a menos que esteja faltando).
    public var record: RecordMode {
        set { lock.withLock { _record = newValue } }
        get {
            // 1. Trait
            if let record = _TestingFramework.shared.testingConfiguration?.record {
                return record
            }
            // 2. withConfiguration
            if let record = _TestingConfiguration.current?.record {
                return record
            }
            // 3. shared
            return lock.withLock { _record }
        }
    }

    /// Define o número máximo de testes que podem ser executados simultaneamente.
    /// - NOTE: Controla a concorrência em operações de snapshot para evitar sobrecarga.
    public var maxConcurrentTests: Int {
        set { lock.withLock { _maxConcurrentTests = newValue } }
        get {
            // 1. Trait
            if let maxConcurrentTests = _TestingFramework.shared.testingConfiguration?.maxConcurrentTests {
                return maxConcurrentTests
            }
            // 2. withConfiguration
            if let maxConcurrentTests = _TestingConfiguration.current?.maxConcurrentTests {
                return maxConcurrentTests
            }
            // 3. shared
            return lock.withLock { _maxConcurrentTests }
        }
    }

    // MARK: - Private properties

    private let lock = NSLock()

    // MARK: - Unsafe properties

    private var _diffTool: DiffTool
    private var _record: RecordMode
    private var _maxConcurrentTests: Int

    private init() {
        _diffTool = .default
        _record = .missing
        _maxConcurrentTests = 3
    }
}
