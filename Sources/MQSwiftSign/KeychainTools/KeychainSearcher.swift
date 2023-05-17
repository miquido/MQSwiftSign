import Foundation

struct KeychainSearcher {

	func searchForItems(in keychain: SecKeychain) throws -> SecKeychainItem {
		let query: [String: Any] = [
			kSecClass as String: kSecClassKey,
			kSecMatchLimit as String: kSecMatchLimitAll,
			kSecReturnAttributes as String: true,
			kSecReturnRef as String: true,
			kSecMatchSearchList as String: [keychain] as CFArray,
		]
		return try SecKeychainItem.search(query)
	}

}
