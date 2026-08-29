import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(key: String, value: String) {
        // Mirror to UserDefaults as rock-solid fallback on physical iOS devices without Keychain entitlement
        UserDefaults.standard.set(value, forKey: key)

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
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "com.harapko.FinanceTrackerSwift",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
        }
        // Resilient fallback to UserDefaults
        return UserDefaults.standard.string(forKey: key)
    }

    func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "com.harapko.FinanceTrackerSwift"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
