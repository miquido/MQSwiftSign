import Foundation

extension SecACL {

	static func getAclContents(_ accessRef: SecAccess) throws -> Array<SecACL> {
		var aclList: CFArray?
		try SecAccessCopyACLList(accessRef, &aclList)
			.onFailThrowing(
				AccessFailed.error(message: "Fetching ACL contents failed"))
		// swift-format-ignore: NeverForceUnwrap
		return aclList as! Array<SecACL>
	}

	func getACLList() throws -> (CFArray?, Data, SecKeychainPromptSelector)? {
		var appList: CFArray?
		var desc: CFString?
		var prompt = SecKeychainPromptSelector()
		try SecACLCopyContents(self, &appList, &desc, &prompt)
			.onFailThrowing(
				AccessFailed.error(message: "Fetching ACL list for item failed"))

		let auths = SecACLCopyAuthorizations(self)
		if !((auths as? [String])?.contains("ACLAuthorizationPartitionID") ?? false) { return nil }

		guard let desc, let xmlData = Data(fromHexEncodedString: desc as NSString as String) else {
			throw AccessFailed.error(message: "Wrong ACL contents")
		}
		return (appList, xmlData, prompt)
	}

	func set(appList: CFArray?, description: CFString, prompt: SecKeychainPromptSelector) throws {
		try SecACLSetContents(self, appList, description, prompt)
			.onFailThrowing(
				AccessFailed.error(message: "Setting new ACL failed"))
	}

}
