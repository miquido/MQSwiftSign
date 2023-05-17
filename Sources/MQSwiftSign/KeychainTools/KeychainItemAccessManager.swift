import Foundation
import MQSwiftSignC
import Security

struct KeychainItemAccessManager {

	private var defaultApps = [
		"/usr/bin/codesign",
		"/usr/bin/productsign",
		"/usr/bin/productbuild",
		"/usr/bin/security",
	]

	func prepareAccessOptions(with customApps: [String]) throws -> SecAccess {
		var appsList = defaultApps
		appsList.append(contentsOf: customApps)
		let appAccessRefs = appsList.createAccessRefs()
		return try SecAccess.create(appAccessRefs as CFArray)
	}

	func modifyAccess(using searchResult: SecKeychainItem, password: String, customPartitions: [String]) throws {
		let accessRef = try SecAccess.get(searchResult)
		let aclList = try SecACL.getAclContents(accessRef)

		for acl in aclList {
			guard let (appList, xmlData, prompt) = try acl.getACLList() else { continue }

			var partitionList = try xmlData.decodeIntoDict()
			partitionList.appendDefaultPartitions(with: customPartitions)
			let data = try partitionList.encodeBackIntoXmlData()
			try acl.set(appList: appList, description: data.hexEncodedString() as CFString, prompt: prompt)

			var (passwd, passwdLength) = try password.getCStringWithLength()
			try SecKeychainItemSetAccessWithPassword(searchResult, accessRef, UInt32(passwdLength), &passwd)
				.onFailThrowing(AccessFailed.error(message: "Setting new access instance failed"))
			Logger.info("ACL contents of private key updated.")
		}
	}

}
