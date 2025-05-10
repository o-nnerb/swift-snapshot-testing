import Foundation

/// Protocolo para definir chaves de configuração de serialização/desserialização com valores padrão.
///
/// Tipos que conformam a `DataSerializationConfigurationKey` representam chaves únicas para
/// configurações específicas, como escalonamento de imagens ou formatação. Cada chave deve definir:
/// 1. Um **tipo associado** (`Value`) que representa o tipo do valor da configuração.
/// 2. Um **valor padrão** estático para a chave.
public protocol DataSerializationConfigurationKey: Sendable {

    /// Tipo do valor associado a essa chave de configuração.
    associatedtype Value: Sendable

    /// Valor padrão para essa chave quando não configurado explicitamente.
    ///
    /// Exemplo: Para uma chave de escalonamento de imagem, o valor padrão pode ser `1.0`.
    static var defaultValue: Value { get }
}
