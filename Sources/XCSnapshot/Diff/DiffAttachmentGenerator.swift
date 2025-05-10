import Foundation
@preconcurrency import XCTest

/// Container para mensagens e anexos gerados durante a comparação de snapshots.
///
/// O `DiffAttachment` armazena uma descrição textual da diferença entre dois valores (como imagens
/// ou dados serializados) junto com anexos visuais (como imagens de comparação), facilitando a identificação
/// visual das divergências.
public struct DiffAttachment: Sendable {

    /// Mensagem descrevendo as diferenças detectadas.
    ///
    /// Exemplo: "Diferença de 5% nos pixels na região central da imagem".
    public let message: String

    /// Coleção de anexos visuais que ilustram as diferenças.
    ///
    /// Pode incluir imagens destacando as áreas divergentes ou diffs gráficos.
    public let attachments: [XCTAttachment]

    /// Inicializa um `DiffAttachment` com mensagem e anexos.
    ///
    /// - Parameters:
    ///   - message: Descrição textual da diferença.
    ///   - attachments: Anexos visuais que complementam a mensagem.
    public init(message: String, attachments: [XCTAttachment]) {
        self.message = message
        self.attachments = attachments
    }
}

/// Protocolo para gerar anexos de comparação (diff) entre valores durante testes de snapshot.
///
/// Tipos que conformam a `DiffAttachmentGenerator` devem implementar a geração de mensagens
/// e anexos visuais (como imagens) que mostram as diferenças entre dois valores de referência e comparativo.
/// É usado para fornecer feedback detalhado quando um snapshot não corresponde à versão armazenada.
public protocol DiffAttachmentGenerator<Value>: Sendable {

    /// Tipo dos valores a serem comparados (ex: `ImageBytes`).
    associatedtype Value: Sendable

    /// Gera uma descrição textual e anexos que destacam as diferenças entre dois valores.
    ///
    /// - Parameters:
    ///   - reference: Valor de referência (snapshot original).
    ///   - diffable: Valor a ser comparado (nova versão do snapshot).
    /// - Returns: `DiffAttachment?`: Tupla com mensagem e anexos se houver diferenças significativas.
    ///
    /// - WARNING: Retorna `nil` se os valores forem considerados idênticos dentro dos critérios de comparação.
    func callAsFunction(
        from reference: Value,
        with diffable: Value
    ) async -> DiffAttachment?
}
