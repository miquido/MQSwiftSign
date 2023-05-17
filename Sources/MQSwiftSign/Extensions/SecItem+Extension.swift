import Foundation

extension SecKeychainItem {

	static func search(_ query: [String: Any]) throws -> SecKeychainItem {
		var searchResult: CFTypeRef?

		Logger.info("Performing search for imported keys in keychain...")
		try SecItemCopyMatching(query as CFDictionary, &searchResult)
			.onFailThrowing(
				KeychainItemSearchFailed.error(message: "Searching imported keys in keychain failed"))

		// swift-format-ignore: NeverForceUnwrap
		let resultArray = searchResult as! CFArray as? Array<[String: Any]>
		guard resultArray?.count == 1, let first = resultArray?.first else {
			throw KeychainItemSearchFailed.error(message: "Wrong keys number was found in keychain")
		}
		Logger.info("Found single key in keychain.")
		// swift-format-ignore: NeverForceUnwrap
		return first[kSecValueRef as String] as! SecKeychainItem
	}

}
