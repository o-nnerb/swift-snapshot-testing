import Foundation

/// Gerenciador de serialização e desserialização de dados com base em uma configuração específica.
///
/// A `DataSerialization` é responsável por converter objetos que conformam ao protocolo
/// `BytesRepresentable` para `Data` (serialização) e vice-versa (desserialização), utilizando a configuração
/// definida em `DataSerializationConfiguration`.
public struct DataSerialization: Sendable {

    // MARK: - Public properties

    /// Configuração de serialização/desserialização a ser utilizada.
    ///
    /// Define parâmetros como escalonamento de imagens, formatação ou outras opções customizadas, acessíveis
    /// via `DataSerializationConfiguration`.
    public var configuration: DataSerializationConfiguration

    // MARK: - Inits

    /// Inicializa uma instância de `DataSerialization` com configuração padrão.
    ///
    /// A configuração padrão inclui valores como `imageScale` definidos em
    /// `DataSerializationConfiguration`.
    public init() {
        configuration = .init()
    }

    // MARK: - Public methods

    /// Desserializa dados binários em uma instância do tipo especificado.
    ///
    /// - Parameter bytesType: Tipo do objeto a ser criado (deve conformar a `BytesRepresentable`).
    /// - Parameter data: Dados binários a serem convertidos.
    /// - Returns: Instância do tipo `Bytes` criada a partir dos dados.
    /// - Throws: Lança erros se a desserialização falhar.
    public func deserialize<Bytes: BytesRepresentable>(
        _ bytesType: Bytes.Type,
        from data: Data
    ) throws -> Bytes {
        let container = BytesContainer.readOnly(data, with: configuration)
        return try Bytes(from: container)
    }

    /// Serializa um objeto em dados binários.
    ///
    /// - Parameter bytes: Objeto a ser serializado (deve conformar a `BytesRepresentable`).
    /// - Returns: Dados binários resultantes da serialização.
    /// - Throws: Lança erros se a serialização falhar.
    public func serialize<Bytes: BytesRepresentable>(_ bytes: Bytes) throws -> Data {
        let container = BytesContainer.writeOnly(with: configuration)
        try bytes.serialize(to: container)
        return container.data
    }
}
