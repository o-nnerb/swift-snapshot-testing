import Foundation

/// Controla quando novos snapshots são gravados durante os testes.
public enum RecordMode: Int16, Sendable {

    /// Impede a gravação de qualquer novo snapshot.
    ///
    /// Os testes falharão se os snapshots atuais não corresponderem aos resultados, mas não haverá
    /// atualização automática.
    case never

    /// Grava apenas snapshots que estão ausentes ou foram modificados.
    ///
    /// Se um snapshot já existe, ele não será substituído, mesmo em caso de divergência.
    case missing

    /// Grava snapshots em todas as execuções, substituindo os existentes.
    ///
    /// Útil para atualizar snapshots intencionalmente após mudanças no UI/UX.
    case always
}
