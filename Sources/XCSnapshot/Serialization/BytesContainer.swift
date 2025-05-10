import Foundation

/// Um contêiner sendable para armazenamento e manipulação de dados durante a serialização/desserialização.
///
/// A `BytesContainer` fornece uma interface para ler e gravar dados, utilizando uma configuração específica
/// de serialização.
public struct BytesContainer: Sendable {

    private enum OperationMode {
        case read
        case write
    }

    private struct OperationNotAllowed: Error {

        fileprivate init() {}
    }

    fileprivate class State: @unchecked Sendable {

        var data: Data {
            get { lock.withLock { _data } }
            set { lock.withLock { _data = newValue } }
        }

        private let lock = NSLock()

        private var _data: Data

        init(_ data: Data) {
            self._data = data
        }
    }

    // MARK: - Public properties

    /// A configuração de serialização de dados usada pelo contêiner.
    ///
    /// Define como os dados serão serializados ou desserializados, incluindo opções como escalonamento de
    /// imagens ou formatação.
    public let configuration: DataSerializationConfiguration

    // MARK: - Internal properties

    var data: Data {
        state.data
    }

    // MARK: - Private properties

    private let operationMode: OperationMode
    private let state: State

    // MARK: - Init

    private init(
        _ operationMode: OperationMode,
        data: Data,
        with configuration: DataSerializationConfiguration
    ) {
        self.operationMode = operationMode
        self.state = .init(data)
        self.configuration = configuration
    }

    // MARK: - Static internal methods

    static func readOnly(
        _ data: Data,
        with configuration: DataSerializationConfiguration
    ) -> BytesContainer {
        BytesContainer(
            .read,
            data: data,
            with: configuration
        )
    }

    static func writeOnly(
        with configuration: DataSerializationConfiguration
    ) -> BytesContainer {
        BytesContainer(
            .write,
            data: Data(),
            with: configuration
        )
    }

    // MARK: - Public methods
    
    /// Recupera os dados armazenados no contêiner.
    ///
    /// - Returns: O objeto `Data` armazenado.
    /// - Throws: Lança um erro se houver falha na leitura dos dados.
    public func read() throws -> Data {
        guard case .read = operationMode else {
            throw OperationNotAllowed()
        }

        return state.data
    }

    /// Grava os dados fornecidos no contêiner.
    ///
    /// - Parameter data: Os dados a serem armazenados.
    /// - Throws: Lança um erro se houver falha na gravação dos dados.
    public func write(_ data: Data) throws {
        guard case .write = operationMode else {
            throw OperationNotAllowed()
        }

        state.data = data
    }
}
