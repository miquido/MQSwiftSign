import Foundation
import MQDo

struct KeychainSearcher {
	var searchForItems: (CFWrapper<SecKeychain>) throws -> CFWrapper<SecKeychainItem>
}

extension KeychainSearcher {
	func searchForItems(in keychain: CFWrapper<SecKeychain>) throws -> CFWrapper<SecKeychainItem> {
		try searchForItems(keychain)
	}
}

extension KeychainSearcher: DisposableFeature {
	static var placeholder: KeychainSearcher {
		KeychainSearcher(
			searchForItems: unimplemented1()
		)
	}
}

extension KeychainSearcher {
	static func system() -> FeatureLoader {
		.disposable { features -> KeychainSearcher in
			let secKeychainItemAPI: SecKeychainItemAPI = try features.instance()
			func searchForItems(_ keychain: CFWrapper<SecKeychain>) throws -> CFWrapper<SecKeychainItem> {
				let query: [String: Any] = [
					kSecClass as String: kSecClassKey,
					kSecMatchLimit as String: kSecMatchLimitAll,
					kSecReturnAttributes as String: true,
					kSecReturnRef as String: true,
					kSecMatchSearchList as String: [keychain.value] as CFArray,
				]
				return try secKeychainItemAPI.search(query)
			}

			return KeychainSearcher(
				searchForItems: searchForItems
			)
		}
	}
}
