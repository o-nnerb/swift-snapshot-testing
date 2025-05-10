import UIKit

extension SnapshotConfiguration where Input: UIViewController, Output == ImageBytes {

    /// Configuração padrão para snapshots de `UIViewController` como imagens.
    ///
    /// Observações:
    ///   - Renderiza a view do controlador em seu estado inicial.
    ///   - Usa valores padrão para precisão e layout.
    public static var image: SnapshotConfiguration {
        return .image()
    }

    /// Cria uma configuração personalizada para snapshots de `UIViewController` como imagens.
    ///
    /// - Parameters:
    ///   - drawHierarchyInKeyWindow: Se `true`, renderiza a hierarquia da view na janela principal
    ///   (útil para layouts dependentes de contexto de janela).
    ///   - precision: Tolerância de pixels para comparação (1 = perfeição, 0.95 = 5% de variação permitida).
    ///   - perceptualPrecision: Tolerância de cores/tons para comparação perceptual.
    ///   - layout: Define como a view será dimensionada (ex: simulando um iPhone 15 Pro Max).
    ///   - traits: Coleção de traços do UI (orientação, tamanho de tela, etc.).
    ///   - delay: Atraso antes de capturar a imagem (útil para esperar animações).
    ///
    /// - Exemplo:
    ///   ```swift
    ///   let config = SnapshotConfiguration<UIViewController, ImageBytes>.image(
    ///       layout: .device(.iPhone15ProMax),
    ///       precision: 0.98
    ///   )
    ///   ```
    public static func image(
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        layout: SnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init(),
        delay: Double? = nil,
        application: UIApplication? = nil
    ) -> SnapshotConfiguration {
        let config = LayoutConfiguration.resolve(layout, with: traits)

        return IdentitySnapshotConfiguration.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision,
            scale: traits.displayScale
        )
        .withWindow(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            application: application,
            operation: { windowConfiguration, pipeline in
                Pipeline.start(Input.self) { @MainActor in
                    SnapshotUIController($0, with: config)
                }
                .connectToWindow(windowConfiguration)
                .layoutIfNeeded()
                .delay(delay)
                .waitLoadingStateIfNeeded()
                .snapshot(pipeline)
            }
        )
        .withLock()
    }
}

