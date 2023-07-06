import Foundation
import MQDo

struct SecACLAPI {
	var contents: (CFWrapper<SecAccess>) throws -> [CFWrapper<SecACL>]
	var list: (CFWrapper<SecACL>) throws -> (CFArray?, Data, SecKeychainPromptSelector)?
	var set: (CFArray?, CFString, SecKeychainPromptSelector, CFWrapper<SecACL>) throws -> Void
}

extension SecACLAPI {
	func getACLContents(_ access: CFWrapper<SecAccess>) throws -> [CFWrapper<SecACL>] {
		try contents(access)
	}

	func getACLList(_ acl: CFWrapper<SecACL>) throws -> (CFArray?, Data, SecKeychainPromptSelector)? {
		try list(acl)
	}

	func setACL(
		appList: CFArray?,
		description: CFString,
		prompt: SecKeychainPromptSelector,
		for acl: CFWrapper<SecACL>
	) throws {
		try set(appList, description, prompt, acl)
	}
}

extension SecACLAPI: DisposableFeature {
	static var placeholder: SecACLAPI {
		SecACLAPI(
			contents: unimplemented1(),
			list: unimplemented1(),
			set: unimplemented4()
		)
	}
}

extension SecACLAPI {
	static func system() -> FeatureLoader {
		.disposable { features in
			SecACLAPI(
				contents: { accessRef in
					let error = AccessFailed.error(message: "Fetching ACL contents failed")
					guard let accessRef = accessRef.value else {
						throw error
					}
					var aclList: CFArray?
					try SecAccessCopyACLList(accessRef, &aclList)
						.onFailThrowing(error)
					// swift-format-ignore: NeverForceUnwrap
					return (aclList as! Array<SecACL>)
						.map {
							$0.wrapped
						}
				},
				list: { acl in
					let error = AccessFailed.error(message: "Fetching ACL list for item failed")
					guard let acl = acl.value else {
						throw error
					}
					var appList: CFArray?
					var desc: CFString?
					var prompt = SecKeychainPromptSelector()
					try SecACLCopyContents(acl, &appList, &desc, &prompt)
						.onFailThrowing(error)

					let auths = SecACLCopyAuthorizations(acl)
					if !((auths as? [String])?.contains("ACLAuthorizationPartitionID") ?? false) {
						return nil
					}

					guard let desc, let xmlData = Data(fromHexEncodedString: desc as NSString as String) else {
						throw AccessFailed.error(message: "Wrong ACL contents")
					}
					return (appList, xmlData, prompt)
				},
				set: { appList, description, prompt, acl in
					let error = AccessFailed.error(message: "Setting new ACL failed")
					guard let acl = acl.value else {
						throw error
					}
					try SecACLSetContents(acl, appList, description, prompt)
						.onFailThrowing(error)
				}
			)
		}
	}
}
