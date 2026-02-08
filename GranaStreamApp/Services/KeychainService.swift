import Foundation
import Security
import os.log

/// Serviço para armazenamento seguro de dados no Keychain
final class KeychainService {
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "KeychainService")
    
    // MARK: - Public Methods
    
    /// Salva um valor no Keychain
    /// - Parameters:
    ///   - value: String a ser salvo
    ///   - key: Chave para identificar o valor
    /// - Throws: KeychainError se a operação falhar
    func set(_ value: String, for key: String) throws {
        guard !key.isEmpty, !value.isEmpty else {
            throw KeychainError.invalidInput
        }
        
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AppConfig.keychainService,
            kSecAttrAccount as String: key
        ]
        
        // Delete existing item primeiro
        SecItemDelete(query as CFDictionary)
        
        let attributes: [String: Any] = query.merging([
            kSecValueData as String: data
        ]) { $1 }
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            let error = KeychainError.saveFailed(status)
            os_log("Keychain save failed: %{public}@", log: Self.log, type: .error, error.debugDescription)
            throw error
        }
        
        os_log("Successfully saved to Keychain for key: %{public}@", log: Self.log, type: .debug, key)
    }

    /// Recupera um valor do Keychain
    /// - Parameter key: Chave do valor a recuperar
    /// - Returns: Valor armazenado ou nil se não encontrado
    /// - Throws: KeychainError se houver erro na recuperação
    func get(_ key: String) throws -> String? {
        guard !key.isEmpty else {
            throw KeychainError.invalidInput
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AppConfig.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            // Item not found é esperado e retorna nil
            if status == errSecItemNotFound {
                os_log("Item not found in Keychain for key: %{public}@", log: Self.log, type: .debug, key)
                return nil
            }
            
            let error = KeychainError.retrievalFailed(status)
            os_log("Keychain retrieval failed: %{public}@", log: Self.log, type: .error, error.debugDescription)
            throw error
        }
        
        guard let data = item as? Data else {
            let error = KeychainError.decodingFailed
            os_log("Failed to decode Keychain data: %{public}@", log: Self.log, type: .error, error.debugDescription)
            throw error
        }
        
        guard let value = String(data: data, encoding: .utf8) else {
            let error = KeychainError.decodingFailed
            os_log("Failed to decode UTF-8 from Keychain data for key: %{public}@", log: Self.log, type: .error, key)
            throw error
        }
        
        os_log("Successfully retrieved from Keychain for key: %{public}@", log: Self.log, type: .debug, key)
        return value
    }

    /// Deleta um valor do Keychain
    /// - Parameter key: Chave do valor a deletar
    /// - Throws: KeychainError se a operação falhar
    func delete(_ key: String) throws {
        guard !key.isEmpty else {
            throw KeychainError.invalidInput
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AppConfig.keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            let error = KeychainError.deletionFailed(status)
            os_log("Keychain deletion failed: %{public}@", log: Self.log, type: .error, error.debugDescription)
            throw error
        }
        
        os_log("Successfully deleted from Keychain for key: %{public}@", log: Self.log, type: .debug, key)
    }
}
