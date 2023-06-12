import Foundation
import MQSwiftSignC
import Security
import MQDo

struct KeychainItemAccessManager {
	var prepareAccessOptions: ([String]) throws -> CFWrapper<SecAccess>
	var modifyAccess: (CFWrapper<SecKeychainItem>, String, [String]) throws -> Void
}

extension KeychainItemAccessManager: DisposableFeature {
	static var placeholder: KeychainItemAccessManager {
		KeychainItemAccessManager(
			prepareAccessOptions: unimplemented1(),
			modifyAccess: unimplemented3()
		)
	}
}

extension KeychainItemAccessManager {
	func prepareAccessOptions(with customApps: [String]) throws -> CFWrapper<SecAccess> {
		try prepareAccessOptions(customApps)
	}

	func modifyAccess(
		using searchResult: CFWrapper<SecKeychainItem>,
		password: String,
		customPartitions: [String]
	) throws {
		try modifyAccess(searchResult, password, customPartitions)
	}
}

struct SystemKeychainItemAccessManager: ImplementationOfDisposableFeature {
	static let defaultApps = [
		"/usr/bin/codesign",
		"/usr/bin/productsign",
		"/usr/bin/productbuild",
		"/usr/bin/security",
	]
	private let secAccessAPI: SecAccessAPI
	private let secACLAPI: SecACLAPI
	private let secKeychainItemAPI: SecKeychainItemAPI

	init(with context: Void, using features: Features) throws {
		secAccessAPI = try features.instance()
		secACLAPI = try features.instance()
		secKeychainItemAPI = try features.instance()
	}

	func prepareActionOptions(_ customApps: [String]) throws -> CFWrapper<SecAccess> {
		var appsList = SystemKeychainItemAccessManager.defaultApps
		appsList.append(contentsOf: customApps)
		let appAccessRefs = appsList.createAccessRefs()
			.compactMap {
				$0?.wrapped
			}
		return try secAccessAPI.create(appAccessRefs)
	}

	func modifyAccess(
		using searchResult: CFWrapper<SecKeychainItem>,
		password: String,
		customPartitions: [String]
	) throws {
		let accessRef = try secAccessAPI.get(searchResult)
		let aclList = try secACLAPI.getACLContents(accessRef)

		for acl in aclList {
			guard let (appList, xmlData, prompt) = try secACLAPI.getACLList(acl) else {
				continue
			}

			var partitionList = try xmlData.decodeIntoDict()
			partitionList.appendDefaultPartitions(with: customPartitions)
			let data = try partitionList.encodeBackIntoXmlData()
			try secACLAPI.setACL(
				appList: appList,
				description: data.hexEncodedString() as CFString,
				prompt: prompt,
				for: acl
			)
			try secKeychainItemAPI.setAccessWithPassword(item: searchResult, access: accessRef, password: password)
			Logger.successInfo("ACL contents of private key updated.")
		}
	}

	var instance: KeychainItemAccessManager {
		.init(
			prepareAccessOptions: prepareActionOptions,
			modifyAccess: modifyAccess(using:password:customPartitions:)
		)
	}
}

extension SecItemImportExportKeyParameters {
	fileprivate static func `default`(using password: String, and access: SecAccess) -> Self {
		return SecItemImportExportKeyParameters(
			version: 0,
			flags: SecKeyImportExportFlags(rawValue: 0),
			passphrase: Unmanaged.passRetained(password as AnyObject),
			alertTitle: nil,
			alertPrompt: nil,
			accessRef: Unmanaged.passUnretained(access),
			keyUsage: nil,
			keyAttributes: nil
		)
	}
}
