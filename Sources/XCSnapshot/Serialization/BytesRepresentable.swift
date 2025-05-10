import Foundation

/// Protocolo para tipos que podem ser serializados/desserializados para um contêiner de bytes.
///
/// Tipos que adotam `BytesRepresentable` devem ser capazes de:
/// 1. Criar uma instância a partir de um `BytesContainer` (desserialização).
/// 2. Escrever seus dados em um `BytesContainer` (serialização).
///
/// Este protocolo é essencial para testes de snapshot, permitindo que objetos sejam convertidos em dados binários
/// para comparação.
public protocol BytesRepresentable: Sendable {

    /// Inicializa uma instância a partir dos dados armazenados no contêiner.
    ///
    /// - Parameter container: O contêiner de bytes que contém os dados a serem lidos.
    /// - Throws: Lança um erro se houver falha na desserialização dos dados.
    init(from container: BytesContainer) throws

    /// Serializa os dados da instância e escreve no contêiner fornecido.
    ///
    /// - Parameter container: O contêiner de bytes onde os dados serão armazenados.
    /// - Throws: Lança um erro se houver falha durante a serialização.
    func serialize(to container: BytesContainer) throws
}
