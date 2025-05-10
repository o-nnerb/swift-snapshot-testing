import Foundation

// MARK: - Representação de Alterações Formatadas
/// Representa um grupo de alterações (hunk) em formato de patch
struct DiffHunk {
    /// Índice inicial na primeira coleção
    let firstStart: Int
    /// Quantidade de linhas na primeira coleção
    let firstLength: Int
    /// Índice inicial na segunda coleção
    let secondStart: Int
    /// Quantidade de linhas na segunda coleção
    let secondLength: Int
    /// Linhas formatadas com indicações de alterações
    let lines: [String]

    /// Gera o cabeçalho do hunk no formato de patch
    var patchMarker: String {
        let firstMarker = "−\(firstStart + 1),\(firstLength)"
        let secondMarker = "+\(secondStart + 1),\(secondLength)"
        return "@@ \(firstMarker) \(secondMarker) @@"
    }

    /// Combina dois hunks em um único
    static func +(lhs: DiffHunk, rhs: DiffHunk) -> DiffHunk {
        DiffHunk(
            firstStart: lhs.firstStart,
            firstLength: lhs.firstLength + rhs.firstLength,
            secondStart: lhs.secondStart,
            secondLength: lhs.secondLength + rhs.secondLength,
            lines: lhs.lines + rhs.lines
        )
    }

    /// Inicializador padrão com valores default
    init(
        firstStart: Int = 0,
        firstLength: Int = 0,
        secondStart: Int = 0,
        secondLength: Int = 0,
        lines: [String] = []
    ) {
        self.firstStart = firstStart
        self.firstLength = firstLength
        self.secondStart = secondStart
        self.secondLength = secondLength
        self.lines = lines
    }
}
