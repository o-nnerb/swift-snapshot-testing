import Foundation

/// Configuração de snapshot simplificada onde o tipo de entrada e saída são o mesmo.
///
/// O `IdentitySnapshotConfiguration` é uma abreviação de
/// `SnapshotConfiguration<Output, Output>`, onde o tipo de entrada e saída são idênticos. É útil quando:
///
/// - O objeto a ser testado não requer transformação adicional (ex: objetos que já estão no formato de bytes desejado).
/// - A serialização/desserialização ocorre diretamente no mesmo tipo.
///
/// - NOTE: O tipo `Output` deve conformar ao protocolo `BytesRepresentable` para ser
/// serializado/desserializado.
public typealias IdentitySnapshotConfiguration<Output: BytesRepresentable> = SnapshotConfiguration<Output, Output>

/// Configuração para definir como os snapshots são gerados, comparados e exibidos durante os testes.
///
/// A `SnapshotConfiguration` define parâmetros como:
/// - O pipeline de processamento do input para o output serializável.
/// - O gerador de anexos de comparação (diff) em caso de divergência.
/// - A extensão do arquivo para snapshots gravados.
///
/// - NOTE: O tipo `Output` deve implementar `BytesRepresentable` para serialização/desserialização.
public struct SnapshotConfiguration<Input: Sendable, Output: BytesRepresentable>: Sendable {

    let pathExtension: String?
    let attachmentGenerator: any DiffAttachmentGenerator<Output>
    let pipeline: Pipeline<Input, Output>

    /// Inicializa uma configuração com pipeline, gerador de diffs e opções de armazenamento.
    ///
    /// - Parameters:
    ///   - pathExtension: Extensão do arquivo usada ao gravar snapshots (ex: `"png"` para imagens).
    ///   - attachmentGenerator: Gerador de mensagens/anexos quando um snapshot falha.
    ///   - pipeline: Fluxo de processamento que converte o `Input` no `Output` serializável.
    ///
    /// Observações:
    ///   - O `Output` deve ser o mesmo tipo que `AttachmentGenerator.Value`.
    ///   - O pipeline é executado antes da comparação para preparar os dados.
    ///
    /// Exemplo:
    ///   ```swift
    ///   let config = SnapshotConfiguration(
    ///       pathExtension: "json",
    ///       attachmentGenerator: MyDiffGenerator(),
    ///       pipeline: Pipeline.start { input in
    ///           return try await encodeToJSON(input)
    ///       }
    ///   )
    ///   ```
    public init<AttachmentGenerator>(
        pathExtension: String? = nil,
        attachmentGenerator: AttachmentGenerator,
        pipeline: Pipeline<Input, Output>
    ) where AttachmentGenerator: DiffAttachmentGenerator<Output> {
        self.pathExtension = pathExtension
        self.attachmentGenerator = attachmentGenerator
        self.pipeline = pipeline
    }

    /// Altera o tipo de entrada da configuração usando um closure para transformar o pipeline existente.
    ///
    /// - Parameter closure: Função que recebe o pipeline atual e retorna um novo com tipo de entrada
    /// alterado.
    /// - Returns: Nova configuração com o novo tipo de input e o mesmo output.
    ///
    /// Observações:
    ///   - Útil para adaptar configurações existentes a novos tipos de entrada.
    ///   - Lança erros propagados pelo closure.
    ///
    /// Exemplo:
    ///   ```swift
    ///   let newConfig = config.map { existingPipeline in
    ///       existingPipeline.prepend { rawInput in
    ///           try await processRawInput(rawInput)
    ///       }
    ///   }
    ///   ```
    public func map<NewInput: Sendable>(
        _ closure: @Sendable (Pipeline<Input, Output>) throws -> Pipeline<NewInput, Output>
    ) rethrows -> SnapshotConfiguration<NewInput, Output> {
        SnapshotConfiguration<NewInput, Output>(
            pathExtension: pathExtension,
            attachmentGenerator: attachmentGenerator,
            pipeline: try closure(pipeline)
        )
    }
}

extension SnapshotConfiguration where Input == Output {

    /// Inicializa uma configuração de snapshot simplificada quando o tipo de entrada e saída são o mesmo.
    ///
    /// Essa inicialização é útil para casos onde o pipeline não requer transformações complexas (ex: quando o
    /// input já está no formato final, como `ImageBytes`).
    ///
    /// - Parameters:
    ///   - pathExtension: Extensão do arquivo para snapshots gravados (ex: `"png"` para imagens).
    ///   - attachmentGenerator: Gerador de mensagens/anexos em caso de divergência entre snapshots.
    ///
    /// Observações:
    ///   - O pipeline é configurado implicitamente como um pass-through (input → output diretamente), já que
    ///   `Input` e `Output` são o mesmo tipo.
    ///   - O `attachmentGenerator` deve gerar diffs para o tipo `Output`.
    ///
    /// Exemplo:
    ///   ```swift
    ///   let config = SnapshotConfiguration<ImageBytes, ImageBytes>(
    ///       pathExtension: "png",
    ///       attachmentGenerator: ImageDiffAttachmentGenerator(precision: 0.95)
    ///   )
    ///   ```
    public init<AttachmentGenerator>(
        pathExtension: String?,
        attachmentGenerator: AttachmentGenerator
    ) where AttachmentGenerator: DiffAttachmentGenerator<Output> {
        self.init(
            pathExtension: pathExtension,
            attachmentGenerator: attachmentGenerator,
            pipeline: .start { $0 }
        )
    }
}
