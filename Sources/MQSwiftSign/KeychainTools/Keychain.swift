import Foundation
import MQDo

struct Keychain {
	var setup: (String, String) throws -> Void
	var `import`: (Data, String, [String]) throws -> Void
	var setACLs: (String, [String]) throws -> Void
}

// syntactic sugar
extension Keychain {
	func setup(keychainName: String, keychainPassword: String) throws {
		try setup(keychainName, keychainPassword)
	}

	func `import`(_ data: Data, using password: String, for applications: [String]) throws {
		try `import`(data, password, applications)
	}

	func setACLs(using password: String, with customPartitions: [String]) throws {
		try setACLs(password, customPartitions)
	}
}

extension Keychain: DisposableFeature {
	static var placeholder: Keychain {
		Keychain(
			setup: unimplemented2(),
			import: unimplemented3(),
			setACLs: unimplemented2()
		)
	}
}

final class SystemKeychain: ImplementationOfDisposableFeature {
	private let worker: SecKeychainAPI
	private let itemAccessManager: KeychainItemAccessManager
	private let searcher: KeychainSearcher
	private let secItemAPI: SecItemAPI
	private var keychain: CFWrapper<SecKeychain>?

	init(with context: Void, using features: Features) throws {
		worker = try features.instance()
		itemAccessManager = try features.instance()
		searcher = try features.instance()
		secItemAPI = try features.instance()
	}

	private func setup(keychainName: String, keychainPassword: String) throws {
		let existingKeychain = worker.get(keychainName)
		worker.delete(existingKeychain)
		let keychain = try worker.create(keychainName, keychainPassword)
		try worker.addToSearchList(keychain)
		try worker.setDefaultSettings(keychain)
		try worker.unlock(keychain, keychainPassword)
		self.keychain = keychain
	}

	private func `import`(_ certificate: Data, using password: String, for customApps: [String]) throws {
		let options = try itemAccessManager.prepareAccessOptions(with: customApps)
		var parameters = try secItemAPI.createParameters(using: password, options: options)
		try secItemAPI.`import`(certificate, &parameters, keychain)
			.onFailThrowing(KeychainItemImportFailed.error(message: "Importing certificate into keychain failed"))
		Logger.successInfo("Certificate imported into a temporary keychain")
	}

	private func setACLs(using password: String, with customPartitions: [String]) throws {
		guard let keychain else {
			throw AccessFailed.error(message: "Keychain not initialized")
		}
		let searchResult = try searcher.searchForItems(in: keychain)
		try itemAccessManager.modifyAccess(
			using: searchResult,
			password: password,
			customPartitions: customPartitions
		)
	}

	var instance: Keychain {
		.init(
			setup: setup(keychainName:keychainPassword:),
			import: `import`(_:using:for:),
			setACLs: setACLs(using:with:)
		)
	}
}
