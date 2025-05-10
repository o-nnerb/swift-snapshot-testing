import UIKit

/// Representa uma imagem serializável para testes de snapshot.
///
/// A `ImageBytes` encapsula uma `UIImage` e fornece métodos para serialização/desserialização,
/// permitindo que imagens sejam comparadas em testes de snapshot.
/// Implementa `BytesRepresentable` para converter a imagem em dados binários (`Data`) e vice-versa.
public struct ImageBytes: BytesRepresentable {

    fileprivate struct ImageScaleKey: DataSerializationConfigurationKey {
        static let defaultValue: Double = 1
    }

    /// A imagem armazenada.
    public let image: UIImage

    /// Inicializa uma instância a partir dos dados armazenados no `BytesContainer`.
    ///
    /// - Parameter container: Contêiner que contém os dados binários da imagem.
    /// - Throws: Lança `BytesSerializationError` se a desserialização falhar (ex: dados corrompidos).
    public init(from container: BytesContainer) throws {
        guard let image = UIImage(
            data: try container.read(),
            scale: container.configuration.imageScale
        ) else {
            throw BytesSerializationError()
        }

        self.image = image
    }

    /// Inicializa uma instância a partir de uma `UIImage`.
    ///
    /// - Parameter image: Imagem a ser convertida em bytes para snapshot.
    public init(_ image: UIImage) {
        self.image = image
    }

    /// Serializa a imagem em dados binários e escreve no contêiner.
    ///
    /// - Parameter container: O contêiner onde os dados da imagem serão armazenados.
    /// - Throws: Lança erro se a serialização falhar (ex: falha ao converter a imagem em `Data`).
    public func serialize(to container: BytesContainer) throws {
        guard let data = image.pngData() else {
            return
        }

        try container.write(data)
    }
}

// MARK: - DataSerializationConfiguration

extension DataSerializationConfiguration {

    /// Define ou obtém o fator de escala para imagens durante a serialização/desserialização.
    ///
    /// Esse valor controla como as imagens são redimensionadas ao serem convertidas para `Data` ou
    /// recuperadas de um `BytesContainer`.
    /// - Observação: O valor padrão é `1.0`.
    public var imageScale: Double {
        get { self[ImageBytes.ImageScaleKey.self] }
        set { self[ImageBytes.ImageScaleKey.self] = newValue }
    }
}

// MARK: - IdentitySnapshotConfiguration

extension IdentitySnapshotConfiguration<ImageBytes> {

    /// Configuração padrão para snapshots de imagens.
    ///
    /// - Observações:
    ///   - Usa valores padrão como `precision: 1` (comparação rigorosa) e `scale: nil` (escala nativa).
    ///   - Usa `ImageDiffAttachmentGenerator` para gerar diffs visuais.
    public static var image: SnapshotConfiguration {
        return .image()
    }

    /// Cria uma configuração personalizada para snapshots de imagens com ajustes de precisão e escala.
    ///
    /// - Parameters:
    ///   - precision: Tolerância de pixels para comparação (ex: `0.95` permite 5% de diferença).
    ///   - perceptualPrecision: Tolerância de cores/tons para comparação perceptual.
    ///   - scale: Fator de escala aplicado às imagens (ex: `2.0` para imagens de alta resolução).
    ///
    /// - Exemplo:
    ///   ```swift
    ///   let config = IdentitySnapshotConfiguration<ImageBytes>.image(
    ///       precision: 0.98,
    ///       scale: 3.0 // Para iPhones com escala 3x
    ///   )
    ///   ```
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        scale: CGFloat? = nil
    ) -> Self {
        return .init(
            pathExtension: "png",
            attachmentGenerator: ImageDiffAttachmentGenerator(
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                scale: scale
            )
        )
    }
}
