import Foundation

/// Representa um erro ocorrido durante a serialização ou desserialização de dados binários.
///
/// Essa estrutura é usada para indicar falhas em operações que envolvem a conversão de dados para ou de um
/// formato binário, como leitura/escrita em um `BytesContainer`.
public struct BytesSerializationError: Error {

    /// Inicializa uma instância de `BytesSerializationError`.
    ///
    /// Este inicializador cria uma instância básica do erro, geralmente usada para indicar falhas genéricas durante
    /// a serialização/desserialização.
    public init() {}
}
