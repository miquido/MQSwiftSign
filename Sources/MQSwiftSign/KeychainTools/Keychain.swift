import Foundation

struct Keychain {

	private let itemAccessManager = KeychainItemAccessManager()
	private let searcher = KeychainSearcher()

	private var keychain: SecKeychain

	init(keychainName: String, keychainPassword: String) throws {
		let existingKeychain = SecKeychain.get(keychainName)
		existingKeychain?.delete()
		self.keychain = try SecKeychain.create(keychainName, keychainPassword)
		try keychain.addToSearchlist()
		try keychain.setDefaultSettings()
		try keychain.unlock(with: keychainPassword)
	}

	func `import`(_ certificate: Data, using password: String, for customApplications: [String]) throws {
		let options = try itemAccessManager.prepareAccessOptions(with: customApplications)
		var parameters = SecItemImportExportKeyParameters.default(using: password, and: options)

		try SecItemImport(
			certificate as CFData,
			".p12" as CFString,
			nil,
			nil,
			SecItemImportExportFlags(rawValue: 0),
			&parameters,
			keychain,
			nil
		)
		.onFailThrowing(KeychainItemImportFailed.error(message: "Importing certificate into keychain failed"))

		Logger.info("Certificate imported into a temporary keychain")
	}

	func setACLs(using password: String, with customPartitions: [String]) throws {
		let searchResult = try searcher.searchForItems(in: keychain)
		try itemAccessManager.modifyAccess(
			using: searchResult, password: password, customPartitions: customPartitions)
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
