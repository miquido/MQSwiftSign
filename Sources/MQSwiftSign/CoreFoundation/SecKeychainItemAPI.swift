import Foundation
import MQDo
import MQSwiftSignC

struct SecKeychainItemAPI {
	var setAccessWithPassword: (CFWrapper<SecKeychainItem>, CFWrapper<SecAccess>, String) throws -> Void
	var search: ([String: Any]) throws -> CFWrapper<SecKeychainItem>
}

extension SecKeychainItemAPI {
	func setAccessWithPassword(
		item: CFWrapper<SecKeychainItem>,
		access: CFWrapper<SecAccess>,
		password: String
	) throws -> Void {
		try setAccessWithPassword(item, access, password)
	}
}

extension SecKeychainItemAPI: DisposableFeature {
	static var placeholder: SecKeychainItemAPI {
		SecKeychainItemAPI(
			setAccessWithPassword: unimplemented3(),
			search: unimplemented1()
		)
	}
}

extension SecKeychainItemAPI {
	static func system() -> FeatureLoader {
		.disposable { features in
			SecKeychainItemAPI(
				setAccessWithPassword: { (item, access, password) throws in
					let error = KeychainSetPropertiesFailed.error(message: "Setting access for item failed")
					guard let item = item.value,
								let access = access.value
					else {
						throw AccessFailed.error(message: "Keychain item or access instance not initialized")
					}
					var (passwd, passwdLength) = try password.getCStringWithLength()
					return try SecKeychainItemSetAccessWithPassword(item, access, UInt32(passwdLength), &passwd)
						.onFailThrowing(error)
				},
				search: { query in
					var searchResult: CFTypeRef?

					Logger.successInfo("Performing search for imported keys in keychain...")
					try SecItemCopyMatching(query as CFDictionary, &searchResult)
						.onFailThrowing(KeychainItemSearchFailed.error(message: "Searching imported keys in keychain failed"))

					// swift-format-ignore: NeverForceUnwrap
					let resultArray = searchResult as! CFArray as? Array<[String: Any]>
					guard resultArray?.count == 1, let first = resultArray?.first else {
						throw KeychainItemSearchFailed.error(message: "Wrong keys number was found in keychain")
					}
					Logger.successInfo("Found single key in keychain.")
					// swift-format-ignore: NeverForceUnwrap
					return (first[kSecValueRef as String] as! SecKeychainItem).wrapped
				}
			)
		}
	}
}
