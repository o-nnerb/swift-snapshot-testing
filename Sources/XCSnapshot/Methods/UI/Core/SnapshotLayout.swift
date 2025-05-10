import CoreGraphics

/// Define como o layout de um componente UI é configurado durante o teste de snapshot.
public enum SnapshotLayout {

    /// Renderiza o componente seguindo as configurações de um dispositivo específico.
    ///
    /// - Parameter configuration: Configuração de layout que define margens de área segura, tamanho
    /// e traços do UI (ex: orientação).
    ///
    /// Exemplo:
    ///   ```swift
    ///   let layout = .device(.iPhone15ProMax)
    ///   ```
    case device(LayoutConfiguration)

    /// Renderiza o componente com um tamanho fixo explícito.
    ///
    /// Útil para garantir consistência em testes independentemente do dispositivo ou configuração.
    ///
    /// - Parameters:
    ///   - width: Largura em pontos.
    ///   - height: Altura em pontos.
    ///
    /// Exemplo:
    ///   ```swift
    ///   let layout = .fixed(width: 375, height: 812) // Tamanho do iPhone 12
    ///   ```
    case fixed(width: CGFloat, height: CGFloat)

    /// Renderiza o componente usando seu tamanho natural (intrinsic content size).
    ///
    /// Ideal para componentes que se ajustam ao conteúdo, como labels ou coleções dinâmicas.
    case sizeThatFits
}
