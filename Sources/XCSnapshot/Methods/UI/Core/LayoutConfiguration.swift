import UIKit

/// Configuração de layout para renderização de elementos em testes de snapshot.
///
/// A `LayoutConfiguration` define propriedades como margens de área segura, tamanho do elemento e traços
/// do dispositivo (ex: orientação, tamanho de tela), permitindo simular diferentes cenários de exibição.
public struct LayoutConfiguration: Sendable {

    // MARK: - Internal static methods

    static func resolve(
        _ snapshotLayout: SnapshotLayout,
        with traits: UITraitCollection
    ) -> LayoutConfiguration {
        switch snapshotLayout {
        case .device(let deviceConfig):
            return .init(
                safeArea: deviceConfig.safeArea,
                size: deviceConfig.size,
                traits: .init(traitsFrom: [deviceConfig.traits, traits])
            )
        case .sizeThatFits:
            return .init(safeArea: .zero, size: nil, traits: traits)
        case .fixed(let width, let height):
            let size = CGSize(width: width, height: height)
            return .init(safeArea: .zero, size: size, traits: traits)
        }
    }

    // MARK: - Public properties

    /// Margens de área segura do layout (ex: para bordas do dispositivo ou status bar).
    ///
    /// Valores padrão: `.zero` (sem margens adicionais).
    public let safeArea: UIEdgeInsets

    /// Tamanho do elemento a ser renderizado.
    ///
    /// Se `nil`, o elemento usa seu tamanho natural.
    public let size: CGSize?

    /// Coleção de traços do UI, como orientação, tamanho do dispositivo e escurecimento.
    ///
    /// Valores padrão: `UITraitCollection()` (valores padrão do sistema).
    public let traits: UITraitCollection

    // MARK: - Inits
    
    /// Inicializa uma configuração de layout com valores padrão ou personalizados.
    ///
    /// - Parameters:
    ///   - safeArea: Margens de área segura (ex: para iPhones com notch).
    ///   - size: Tamanho desejado do elemento (opcional).
    ///   - traits: Traços do UI (ex: orientação portrait/landscape).
    public init(
        safeArea: UIEdgeInsets = .zero,
        size: CGSize? = nil,
        traits: UITraitCollection = .init()
    ) {
        self.safeArea = safeArea
        self.size = size
        self.traits = traits
    }
}

// MARK: - iPhone SE
extension LayoutConfiguration {

    public static let iPhoneSE: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        let size = CGSize(width: 320, height: 568)
        return .init(safeArea: safeArea, size: size, traits: .iPhoneSE())
    }()
}

// MARK: - iPhone 8
extension LayoutConfiguration {

    public static let iPhone8: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        let size = CGSize(width: 375, height: 667)
        return .init(safeArea: safeArea, size: size, traits: .iPhone8())
    }()

    public static let iPhone8Plus: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        let size = CGSize(width: 414, height: 736)
        return .init(safeArea: safeArea, size: size, traits: .iPhone8())
    }()
}

// MARK: - iPhone X
extension LayoutConfiguration {

    public static let iPhoneX: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 375, height: 812)
        return .init(safeArea: safeArea, size: size, traits: .iPhoneX())
    }()

    public static let iPhoneXsMax: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 414, height: 896)
        return .init(safeArea: safeArea, size: size, traits: .iPhoneXs())
    }()

    public static let iPhoneXr: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 414, height: 896)
        return .init(safeArea: safeArea, size: size, traits: .iPhoneXr())
    }()
}

// MARK: - iPhone 12
extension LayoutConfiguration {
    public static let iPhone12Mini: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 50, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 375, height: 812)
        return .init(safeArea: safeArea, size: size, traits: .iPhone12())
    }()

    public static let iPhone12: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 390, height: 844)
        return .init(safeArea: safeArea, size: size, traits: .iPhone12())
    }()

    public static let iPhone12Pro: LayoutConfiguration = {
        return .iPhone12
    }()

    public static let iPhone12ProMax: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 428, height: 926)
        return .init(safeArea: safeArea, size: size, traits: .iPhone12())
    }()
}

// MARK: - iPhone 13
extension LayoutConfiguration {
    public static let iPhone13Mini: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 50, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 375, height: 812)
        return .init(safeArea: safeArea, size: size, traits: .iPhone13())
    }()

    public static let iPhone13: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 390, height: 844)
        return .init(safeArea: safeArea, size: size, traits: .iPhone13())
    }()

    public static let iPhone13Pro: LayoutConfiguration = {
        return .iPhone13
    }()

    public static let iPhone13ProMax: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 428, height: 926)
        return .init(safeArea: safeArea, size: size, traits: .iPhone13())
    }()
}

// MARK: - iPhone 14
extension LayoutConfiguration {

    public static let iPhone14: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 390, height: 844)
        return .init(safeArea: safeArea, size: size, traits: .iPhone14())
    }()

    public static let iPhone14Plus: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 428, height: 926)
        return .init(safeArea: safeArea, size: size, traits: .iPhone14())
    }()

    public static let iPhone14Pro: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 393, height: 852)
        return .init(safeArea: safeArea, size: size, traits: .iPhone14())
    }()

    public static let iPhone14ProMax: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 430, height: 932)
        return .init(safeArea: safeArea, size: size, traits: .iPhone14())
    }()
}

// MARK: - iPhone 15
extension LayoutConfiguration {
    public static let iPhone15: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 393, height: 852)
        return .init(safeArea: safeArea, size: size, traits: .iPhone15())
    }()

    public static let iPhone15Plus: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 430, height: 932)
        return .init(safeArea: safeArea, size: size, traits: .iPhone15())
    }()

    public static let iPhone15Pro: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 393, height: 852)
        return .init(safeArea: safeArea, size: size, traits: .iPhone15())
    }()

    public static let iPhone15ProMax: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 430, height: 932)
        return .init(safeArea: safeArea, size: size, traits: .iPhone15())
    }()
}

// MARK: - iPhone 16
extension LayoutConfiguration {
    public static let iPhone16: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 393, height: 852)
        return .init(safeArea: safeArea, size: size, traits: .iPhone16())
    }()

    public static let iPhone16Plus: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 430, height: 932)
        return .init(safeArea: safeArea, size: size, traits: .iPhone16())
    }()

    public static let iPhone16Pro: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 402, height: 874)
        return .init(safeArea: safeArea, size: size, traits: .iPhone16())
    }()

    public static let iPhone16ProMax: LayoutConfiguration = {
        let safeArea = UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
        let size = CGSize(width: 440, height: 956)
        return .init(safeArea: safeArea, size: size, traits: .iPhone16())
    }()
}
