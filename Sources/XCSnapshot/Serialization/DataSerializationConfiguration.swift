import Foundation

/// Configuração de parâmetros usados durante a serialização/desserialização de dados.
///
/// A `DataSerializationConfiguration` armazena valores de configuração específicos, acessíveis via
/// chaves que conformam ao protocolo `DataSerializationConfigurationKey`.
/// Essas configurações controlam comportamentos como escalonamento de imagens ou formatação durante a
/// conversão de dados.
public struct DataSerializationConfiguration: Sendable {

    // MARK: - Private properties

    private var values: [ObjectIdentifier: Sendable]

    // MARK: - Inits

    init() {
        self.values = [:]
    }

    // MARK: - Public methods

    /// Acessa ou define um valor de configuração associado a uma chave específica.
    ///
    /// - Parameter keyType: Tipo da chave que identifica a configuração (deve conformar a
    /// `DataSerializationConfigurationKey`).
    /// - Returns: O valor armazenado para a chave fornecida.
    public subscript<Key: DataSerializationConfigurationKey>(_ keyType: Key.Type) -> Key.Value {
        get { values[ObjectIdentifier(keyType)] as? Key.Value ?? Key.defaultValue }
        set { values[ObjectIdentifier(keyType)] = newValue }
    }
}
