import Foundation

/// Gerenciador centralizado de tasks com suporte a cancelamento automático
/// Elimina a necessidade de múltiplos @State variables para gerenciar tasks
@MainActor
final class TaskManager {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var activeTaskTokens: [String: UUID] = [:]
    
    /// Executa uma operação assíncrona e gerencia seu ciclo de vida
    /// Se uma task com mesmo ID já existe, cancela a anterior
    func execute(
        id: String,
        operation: @escaping () async -> Void
    ) {
        // Cancelar task anterior se existir
        activeTasks[id]?.cancel()

        let token = UUID()
        activeTaskTokens[id] = token

        let task = Task { [weak self] in
            await operation()
            await self?.finishTask(id: id, token: token)
        }

        activeTasks[id] = task
    }
    
    /// Executa uma operação e retorna o resultado de forma sincronizada
    func executeAndWait<T>(
        id: String,
        operation: @escaping () async -> T
    ) async -> T {
        // Cancelar task anterior se existir
        activeTasks[id]?.cancel()
        
        let task = Task {
            await operation()
        }
        
        // Armazenar temporariamente (não funciona com tipo genérico)
        // activeT asks[id] = task
        
        let result = await task.value
        return result
    }
    
    /// Cancela uma task específica
    func cancel(id: String) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        activeTaskTokens[id] = nil
    }
    
    /// Cancela todas as tasks ativas
    func cancelAll() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        activeTaskTokens.removeAll()
    }
    
    /// Verifica se uma task está ativa
    func isRunning(id: String) -> Bool {
        guard let task = activeTasks[id] else { return false }
        return !task.isCancelled
    }
    
    /// Deinicializa e cancela todas as tasks
    deinit {
        // Cancelamento de tasks é seguro fora do context de MainActor
        activeTasks.values.forEach { $0.cancel() }
    }
    
    private func finishTask(id: String, token: UUID) {
        guard activeTaskTokens[id] == token else { return }
        activeTasks[id] = nil
        activeTaskTokens[id] = nil
    }
}

// MARK: - Convenience Methods for Common Task IDs

extension TaskManager {
    static let shared = TaskManager()
    
    enum CommonTaskID: String {
        case initialLoad = "initialLoad"
        case reload = "reload"
        case search = "search"
        case delete = "delete"
        case create = "create"
        case update = "update"
        case settle = "settle"
        case undo = "undo"
    }
    
    /// Execute com IDs comuns
    func executeCommon(
        id: CommonTaskID,
        operation: @escaping () async -> Void
    ) {
        execute(id: id.rawValue, operation: operation)
    }
    
    /// Execute and wait com IDs comuns
    func executeCommonAndWait<T>(
        id: CommonTaskID,
        operation: @escaping () async -> T
    ) async -> T {
        await executeAndWait(id: id.rawValue, operation: operation)
    }
    
    /// Cancelar com IDs comuns
    func cancelCommon(id: CommonTaskID) {
        cancel(id: id.rawValue)
    }
    
    /// Verificar se task comum está rodando
    func isCommonRunning(id: CommonTaskID) -> Bool {
        isRunning(id: id.rawValue)
    }
}
