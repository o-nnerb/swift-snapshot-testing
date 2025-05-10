import Foundation

// MARK: - Estrutura de Diferença
/// Estrutura que representa uma diferença entre dois conjuntos de elementos.
struct Difference<Element> {
    /// Origem dos elementos na comparação
    enum Origin {
        case first  // Elemento exclusivo da primeira coleção
        case second // Elemento exclusivo da segunda coleção
        case common // Elemento presente em ambas as coleções
    }

    /// Elementos envolvidos na diferença
    let elements: [Element]
    /// Origem dos elementos (primeira coleção, segunda ou comum)
    let origin: Origin
}

extension Array where Element: Hashable {

    // MARK: - Função Principal de Comparação
    /// Calcula as diferenças entre duas coleções usando o algoritmo de subsequência comum mais longa (LCS).
    /// - Parameters:
    ///   - first: Primeira coleção a ser comparada
    ///   - second: Segunda coleção a ser comparada
    /// - Returns: Lista de diferenças identificadas
    func diffing(_ other: [Element]) -> [Difference<Element>] {
        // 1. Mapeia índices dos elementos da primeira coleção
        var elementIndices = [Element: [Int]]()
        for (index, element) in enumerated() {
            elementIndices[element, default: []].append(index)
        }

        // 2. Encontra a subsequência comum mais longa (LCS)
        var longestSubsequence = (
            overlap: [Int: Int](), // Tabela de sobreposição
            firstIndex: 0,         // Índice inicial na primeira coleção
            secondIndex: 0,        // Índice inicial na segunda coleção
            length: 0              // Comprimento da subsequência
        )

        // Itera sobre a segunda coleção para encontrar correspondências
        for pair in other.enumerated() {
            guard let indices = elementIndices[pair.element] else { continue }

            for firstIndex in indices {
                let currentLength = (longestSubsequence.overlap[firstIndex - 1] ?? 0) + 1
                var newOverlap = longestSubsequence.overlap
                newOverlap[firstIndex] = currentLength

                // Atualiza a subsequência mais longa encontrada
                if currentLength > longestSubsequence.length {
                    longestSubsequence.overlap = newOverlap
                    longestSubsequence.firstIndex = firstIndex - currentLength + 1
                    longestSubsequence.secondIndex = pair.offset - currentLength + 1
                    longestSubsequence.length = currentLength
                }
            }
        }

        // 3. Caso não haja subsequência comum
        guard longestSubsequence.length > 0 else {
            return [
                Difference(elements: self, origin: .first),
                Difference(elements: other, origin: .second)
            ].filter { !$0.elements.isEmpty }
        }

        // 4. Divide as coleções em partes para análise recursiva
        let (firstPart, secondPart) = (
            Array(self.prefix(upTo: longestSubsequence.firstIndex)),
            Array(other.prefix(upTo: longestSubsequence.secondIndex))
        )

        let (firstRemainder, secondRemainder) = (
            Array(self.suffix(from: longestSubsequence.firstIndex + longestSubsequence.length)),
            Array(other.suffix(from: longestSubsequence.secondIndex + longestSubsequence.length))
        )

        // 5. Combina os resultados das partes analisadas recursivamente
        return firstPart.diffing(secondPart)
        + [Difference(
            elements: Array(self[longestSubsequence.firstIndex ..< longestSubsequence.firstIndex + longestSubsequence.length]),
            origin: .common
        )]
        + firstRemainder.diffing(secondRemainder)
    }
}

extension Array<Difference<String>> {
    
    /// Agrupa as diferenças em hunks com contexto
    /// - Parameters:
    ///   - diffs: Lista de diferenças a serem agrupadas
    ///   - context: Número de linhas de contexto a serem incluídas
    /// - Returns: Lista de hunks formatados
    func groupping(context: Int = 4) -> [DiffHunk] {
        let figureSpace = "\u{2007}" // Espaço de figura (para alinhamento)

        // Processa cada diferença e agrupa em hunks
        let (finalHunk, hunks) = reduce(into: (current: DiffHunk(), hunks: [DiffHunk]())) { state, diff in
            let count = diff.elements.count

            switch diff.origin {
            // Caso: Elementos comuns com contexto grande
            case .common where count > context * 2:
                let prefixLines = diff.elements.prefix(context).map(addPrefix(figureSpace))
                let suffixLines = diff.elements.suffix(context).map(addPrefix(figureSpace))

                let newHunk = state.current + DiffHunk(
                    firstLength: context,
                    secondLength: context,
                    lines: prefixLines
                )

                state.current = DiffHunk(
                    firstStart: state.current.firstStart + state.current.firstLength + count - context,
                    firstLength: context,
                    secondStart: state.current.secondStart + state.current.secondLength + count - context,
                    secondLength: context,
                    lines: suffixLines
                )

                // Adiciona hunk anterior se contiver alterações
                if newHunk.lines.contains(where: { $0.hasPrefix("−") || $0.hasPrefix("+") }) {
                    state.hunks.append(newHunk)
                }

            // Caso: Elementos comuns com hunk vazio
            case .common where state.current.lines.isEmpty:
                let suffixLines = diff.elements.suffix(context).map(addPrefix(figureSpace))
                state.current = state.current + DiffHunk(
                    firstStart: count - suffixLines.count,
                    firstLength: suffixLines.count,
                    secondStart: count - suffixLines.count,
                    secondLength: suffixLines.count,
                    lines: suffixLines
                )

            // Caso: Elementos comuns normais
            case .common:
                let lines = diff.elements.map(addPrefix(figureSpace))
                state.current = state.current + DiffHunk(
                    firstLength: count,
                    secondLength: count,
                    lines: lines
                )

            // Caso: Remoções (elementos da primeira coleção)
            case .first:
                state.current = state.current + DiffHunk(
                    firstLength: count,
                    lines: diff.elements.map(addPrefix("−"))
                )

            // Caso: Adições (elementos da segunda coleção)
            case .second:
                state.current = state.current + DiffHunk(
                    secondLength: count,
                    lines: diff.elements.map(addPrefix("+"))
                )
            }
        }

        // Retorna os hunks acumulados + o último hunk (se válido)
        return finalHunk.lines.isEmpty ? hunks : hunks + [finalHunk]
    }
}

// MARK: - Agrupamento de Alterações com Contexto
/// Função auxiliar para adicionar prefixos em linhas
private func addPrefix(_ prefix: String) -> (String) -> String {
    { "\(prefix)\($0)\($0.hasSuffix(" ") ? "¬" : "")" }
}
