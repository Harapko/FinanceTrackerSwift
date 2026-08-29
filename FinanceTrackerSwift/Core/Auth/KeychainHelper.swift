import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(key: String, value: String) {
        // 1. Direct UserDefaults persistence (rock-solid on iOS device sandboxes)
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()

        // 2. Best-effort Keychain storage
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "com.harapko.FinanceTrackerSwift",
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        // 1. Check UserDefaults first
        if let val = UserDefaults.standard.string(forKey: key), !val.trimmingCharacters(in: .whitespaces).isEmpty {
            return val.trimmingCharacters(in: .whitespaces)
        }

        // 2. Fallback to Keychain
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "com.harapko.FinanceTrackerSwift",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let str = String(data: data, encoding: .utf8), !str.trimmingCharacters(in: .whitespaces).isEmpty {
            let cleanStr = str.trimmingCharacters(in: .whitespaces)
            UserDefaults.standard.set(cleanStr, forKey: key)
            UserDefaults.standard.synchronize()
            return cleanStr
        }
        return nil
    }

    func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "com.harapko.FinanceTrackerSwift"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
