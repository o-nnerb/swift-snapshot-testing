import Foundation

/// Define formatadores para mensagens de comparação de snapshots.
///
/// A `DiffTool` gera uma saída (texto) que será exibida no console do Xcode quando um snapshot falhar. Essa
/// saída pode ser:
/// - Uma mensagem de erro instrutiva (`default`).
/// - Um comando Shell para ferramentas externas (ex: `ksdiff` para o Kaleidoscope).
///
/// - WARNING: A saída gerada **não é executada automaticamente** pela biblioteca. O desenvolvedor ou CI
/// pode processá-la manualmente ou via scripts.
public struct DiffTool: Sendable, ExpressibleByStringLiteral {

    /// Formata uma saída para o [Kaleidoscope](http://kaleidoscope.app).
    ///
    /// Gera um comando Shell que, quando executado externamente, abre o Kaleidoscope para comparar os
    /// arquivos.
    ///
    /// - Exemplo de saída:
    ///   ```bash
    ///   ksdiff /caminho/arquivo-reference.png /caminho/arquivo-failed.png
    ///   ```
    ///
    /// - WARNING: Requer que o Kaleidoscope esteja instalado.
    public static let ksdiff = Self {
        "ksdiff \($0) \($1)"
    }

    /// Formato padrão (mensagem de erro legível no console).
    ///
    /// Gera uma mensagem que orienta o desenvolvedor a configurar uma ferramenta avançada:
    ///
    /// ```plaintext
    /// ⚠️ Diferença detectada
    ///
    /// @-
    /// "file://\($0)"
    /// @+
    /// "file://\($1)"
    ///
    /// Para configurar uma saída específica para uma ferramenta de diff, use o 'withSnapshotTesting'. Por exemplo:
    ///
    ///     withSnapshotTesting(diffTool: .ksdiff) {
    ///         // ...
    ///     }
    /// ```
    ///
    /// - Observação: Útil em ambientes onde não há execução automática de comandos (ex: CI).
    public static let `default` = Self {
        """
        ⚠️ Diferença detectada.
        
        @-
        "\($0)"
        @+
        "\($1)"
        
        Para configurar uma saída específica para uma ferramenta de diff, use o \
        'withSnapshotTesting'. Por exemplo:
        
          withSnapshotTesting(diffTool: .ksdiff) {
              // ...
          }
        """
    }

    private var tool: @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String

    /// Inicializa um formatação personalizada.
    ///
    /// - Parameter tool: Função que gera a saída (texto) a partir dos caminhos dos arquivos.
    ///   - `currentFilePath`: Caminho do arquivo de referência.
    ///   - `failedFilePath`: Caminho do arquivo comparado.
    ///   - Retorna: String que será exibida no console ou processada externamente.
    ///
    /// - Exemplo:
    ///   ```swift
    ///   DiffTool { current, failed in
    ///       "diff \(current) \(failed)"
    ///   }
    ///   ```
    public init(
        _ tool: @escaping @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String
    ) {
        self.tool = tool
    }

    /// Inicializa a ferramenta a partir de uma *string* literal.
    ///
    /// - Parameter value: Texto ou comando que será formatado com os caminhos dos arquivos.
    ///
    /// - Exemplo: `DiffTool("open -a Kaleidoscope $0 $1")` gera `open -a Kaleidoscope /caminho1 /caminho2`.
    public init(stringLiteral value: StringLiteralType) {
        self.tool = { "\(value) \($0) \($1)" }
    }

    /// Gera a saída de comparação.
    ///
    /// - Parameter currentFilePath: Caminho do arquivo de referência.
    /// - Parameter failedFilePath: Caminho do arquivo comparado.
    /// - Returns:
    ///   - Se usar `default`: Mensagem de erro instrutiva.
    ///   - Se usar `ksdiff`: Comando para executar o Kaleidoscope.
    ///   - Se usar uma string/tool personalizada: O texto definido.
    ///
    /// - NOTE: A saída é exibida diretamente no console do Xcode ou no Terminal e pode ser copiada para execução
    /// manual.
    public func callAsFunction(currentFilePath: String, failedFilePath: String) -> String {
        self.tool(currentFilePath, failedFilePath)
    }
}
