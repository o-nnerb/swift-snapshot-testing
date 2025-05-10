import UIKit
import XCTest

/// Gera mensagens e anexos visuais para destacar diferenças entre imagens em testes de snapshot.
///
/// A `ImageDiffAttachmentGenerator` compara duas instâncias de `ImageBytes` (imagens serializadas)
/// e retorna uma descrição textual da diferença, junto com anexos visuais (como imagens destacando as divergências).
/// É usada para facilitar a identificação de alterações visuais em testes de UI.
public struct ImageDiffAttachmentGenerator: DiffAttachmentGenerator {

    private let precision: Float
    private let perceptualPrecision: Float
    private let scale: CGFloat?

    /// Inicializa o gerador com parâmetros de precisão e escalonamento.
    ///
    /// - Parameter precision: Limite de diferença de pixels permitida (ex: `1.0` para pixels idênticos).
    /// - Parameter perceptualPrecision: Limite de diferença perceptual de cores (útil para comparações
    /// menos rigorosas).
    /// - Parameter scale: Fator de escala aplicado às imagens durante a comparação (ex: `2.0` para
    /// imagens de alta resolução).
    public init(
        precision: Float,
        perceptualPrecision: Float,
        scale: CGFloat?
    ) {
        self.precision = precision
        self.perceptualPrecision = perceptualPrecision
        self.scale = scale
    }

    /// Compara duas imagens e gera uma mensagem ou anexos destacando as diferenças.
    ///
    /// - Parameter reference: Imagem de referência (snapshot original).
    /// - Parameter diffable: Imagem a ser comparada (nova versão do snapshot).
    /// - Returns: `DiffAttachment` contendo uma mensagem descritiva e anexos visuais se houver diferenças significativas.
    public func callAsFunction(
        from reference: ImageBytes,
        with diffable: ImageBytes
    ) async -> DiffAttachment? {
        guard let message = reference.image.compare(
            diffable.image,
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ) else { return nil }

        let difference = reference.image.substract(diffable.image, scale: scale)
        let oldAttachment = XCTAttachment(image: reference.image)
        oldAttachment.name = "reference"
        let isEmptyImage = diffable.image.size == .zero
        let newAttachment = await XCTAttachment(image: isEmptyImage ? UIImage.empty : diffable.image)
        newAttachment.name = "failure"
        let differenceAttachment = XCTAttachment(image: difference)
        differenceAttachment.name = "difference"

        return DiffAttachment(
            message: message,
            attachments: [oldAttachment, newAttachment, differenceAttachment]
        )
    }
}
