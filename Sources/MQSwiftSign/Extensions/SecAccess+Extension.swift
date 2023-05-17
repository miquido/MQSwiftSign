import Foundation

extension SecAccess {

	static func create(_ array: CFArray) throws -> SecAccess {
		var accessRef: SecAccess?
		try SecAccessCreate(
			"SecAccess - imported private key" as CFString,
			array,
			&accessRef
		)
		.onFailThrowing(AccessFailed.error(message: "Access instance creation failed"))
		guard let accessRef else {
			throw AccessFailed.error(message: "Access instance creation failed")
		}
		Logger.info("Access options prepared.")
		return accessRef
	}

	static func get(_ item: SecKeychainItem) throws -> SecAccess {
		var accessRef: SecAccess?
		try SecKeychainItemCopyAccess(item, &accessRef)
			.onFailThrowing(
				AccessFailed.error(message: "Fetching access for item failed"))
		guard let accessRef else {
			throw AccessFailed.error(message: "Fetching access for item failed")
		}
		return accessRef
	}

}
