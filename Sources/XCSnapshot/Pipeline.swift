import Foundation

/// A `Pipeline` permite criar fluxos de processamento que transformam um valor de tipo `Input` em um tipo
/// `Output` através de etapas definidas. Útil em cenários como a preparação de dados para testes de snapshot,
/// onde podem ser aplicadas múltiplas operações sequenciais.
///
/// - NOTE: As etapas da pipeline podem incluir operações como serialização, transformação de dados ou processamento assíncrono.
public struct Pipeline<Input: Sendable, Output: Sendable>: Sendable {

    private let block: @Sendable (Input) async throws -> Output

    private init(_ block: @escaping @Sendable (Input) async throws -> Output) {
        self.block = block
    }

    /// Cria uma pipeline com o primeiro bloco de transformação.
    ///
    /// - Parameters:
    ///   - inputType: Tipo do input (geralmente inferido automaticamente).
    ///   - block: Função assíncrona que transforma o `Input` em `Output`.
    /// - Returns: Uma nova instância de `Pipeline` configurada com o bloco inicial.
    ///
    /// - Exemplo:
    ///   ```swift
    ///   let pipeline = Pipeline<Int, String>.start { input in
    ///       return "Resultado: \(input * 2)"
    ///   }
    ///   ```
    public static func start(_ inputType: Input.Type = Input.self, _ block: @escaping @Sendable (Input) async throws -> Output) -> Self {
        .init(block)
    }

    /// Executa a pipeline com um valor de entrada.
    ///
    /// - Parameter input: Valor de entrada a ser processado.
    /// - Returns: O valor de saída resultante após aplicar todas as etapas da pipeline.
    /// - Throws: Pode lançar erros definidos nos blocos da pipeline.
    ///
    /// Exemplo:
    ///   ```swift
    ///   let result = try await pipeline(5) // Retorna "Resultado: 10"
    ///   ```
    public func callAsFunction(_ input: Input) async throws -> Output {
        try await block(input)
    }
}

extension Pipeline {

    /// Adiciona uma etapa após a pipeline existente, transformando o output atual em um novo tipo.
    ///
    /// - Parameter block: Função assíncrona que recebe o output atual e retorna o novo tipo.
    /// - Returns: Nova pipeline com o mesmo input original, mas um novo output final.
    ///
    /// Permite encadear múltiplas transformações (ex: serializar → compactar → encriptar).
    ///
    /// Exemplo:
    ///   ```swift
    ///   let pipeline = Pipeline<Int, String>.start { input in
    ///       return "Resultado \(input * 2)"
    ///   }
    ///   let newPipeline = pipeline.chain { str in
    ///       return str.uppercased()
    ///   }
    ///   try await newPipeline(5) // Retorna "RESULTADO 10"
    ///   ```
    public func chain<NewOutput: Sendable>(
        _ block: @escaping @Sendable (Output) async throws -> NewOutput
    ) -> Pipeline<Input, NewOutput> {
        .start { input in
            let output = try await self(input)
            return try await block(output)
        }
    }

    /// Adiciona uma etapa antes da pipeline existente, convertendo um novo tipo de input no tipo atual.
    ///
    /// - Parameter block: Função assíncrona que converte o novo input em um valor do tipo original.
    /// - Returns: Nova pipeline com o novo tipo de input, mas mantendo o output final.
    ///
    /// Útil para pré-processar dados antes de iniciar o fluxo principal.
    ///
    /// Exemplo:
    ///   ```swift
    ///   let originalPipeline = Pipeline<Int, String>.start { input in
    ///       return "\(input)"
    ///   }
    ///   let newPipeline = originalPipeline.prepend { str in
    ///       return Int(str) ?? 0
    ///   }
    ///   try await newPipeline("3") // Retorna "3" como String
    ///   ```
    public func prepend<NewInput: Sendable>(
        _ block: @escaping @Sendable (NewInput) async throws -> Input
    ) -> Pipeline<NewInput, Output> {
        .start { newInput in
            let input = try await block(newInput)
            return try await self(input)
        }
    }

    /// Introduz um atraso antes da execução da pipeline.
    ///
    /// - Parameter delay: Tempo de atraso em segundos (opcional). Se `nil`, não aplica atraso.
    /// - Returns: Nova pipeline com o mesmo input e output, mas com o atraso configurado.
    ///
    /// Útil para simular tempos de resposta ou sincronizar operações assíncronas.
    ///
    /// - Exemplo:
    ///   ```swift
    ///   let delayedPipeline = pipeline.delay(2.0)
    ///
    ///   // Executa a pipeline após 2 segundos de espera
    ///   try await delayedPipeline(input)
    ///   ```
    public func delay(_ delay: Double?) -> Pipeline<Input, Output> {
        chain {
            if let delay {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            return $0
        }
    }
}
