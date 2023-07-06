import Foundation
import MQDo

struct SecItemAPI {
	var `import`: (Data, inout SecItemImportExportKeyParameters, CFWrapper<SecKeychain>?) -> OSStatus
	var createParameters: (String, CFWrapper<SecAccess>?) throws -> SecItemImportExportKeyParameters
}

extension SecItemAPI: DisposableFeature {
	static var placeholder: SecItemAPI {
		SecItemAPI(
			import: { _, _, _ in errSecSuccess },
			createParameters: { _, _ in SecItemImportExportKeyParameters() }
		)
	}
}

extension SecItemAPI {
	func createParameters(
		using password: String,
		options: CFWrapper<SecAccess>?
	) throws -> SecItemImportExportKeyParameters {
		try createParameters(password, options)
	}
}

extension SecItemAPI {
	static func system() -> FeatureLoader {
		.disposable { features in
			SecItemAPI(
				import: {
					(
						certificate,
						parameters: inout SecItemImportExportKeyParameters,
						keychain: CFWrapper<SecKeychain>?
					) -> OSStatus in
					guard let keychain = keychain?.value else {
						return errSecParam
					}
					return SecItemImport(
						certificate as CFData,
						".p12" as CFString,
						nil,
						nil,
						SecItemImportExportFlags(rawValue: 0),
						&parameters,
						keychain,
						nil
					)
				},
				createParameters: {
					(password, access: CFWrapper<SecAccess>?) throws -> SecItemImportExportKeyParameters in
					guard let access = access?.value else {
						throw KeychainSetPropertiesFailed.error()
					}
					return SecItemImportExportKeyParameters.default(using: password, and: access)
				}
			)
		}
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
