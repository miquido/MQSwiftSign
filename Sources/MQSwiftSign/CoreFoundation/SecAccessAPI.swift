import Foundation
import MQDo

struct SecAccessAPI {
	var create: ([CFWrapper<SecTrustedApplication>]) throws -> CFWrapper<SecAccess>
	var get: (CFWrapper<SecKeychainItem>) throws -> CFWrapper<SecAccess>
}

extension SecAccessAPI: DisposableFeature {
	static var placeholder: SecAccessAPI {
		SecAccessAPI(
			create: unimplemented1(),
			get: unimplemented1()
		)
	}
}

extension SecAccessAPI {
	static func system() -> FeatureLoader {
		.disposable { features in
			return SecAccessAPI(
				create: { trustedApplications in
					var accessRef: SecAccess?
					try SecAccessCreate(
						"SecAccess - imported private key" as CFString,
						trustedApplications.compactMap {
							$0.value
						} as CFArray,
						&accessRef
					)
						.onFailThrowing(AccessFailed.error(message: "Access instance creation failed"))
					guard let accessRef else {
						throw AccessFailed.error(message: "Access instance creation failed")
					}
					Logger.successInfo("Access options prepared.")
					return accessRef.wrapped
				},
				get: {
					let error = AccessFailed.error(message: "Fetching access for item failed")
					guard let item = $0.value else {
						throw error
					}
					var accessRef: SecAccess?
					try SecKeychainItemCopyAccess(item, &accessRef)
						.onFailThrowing(error)
					guard let accessRef else {
						throw error
					}
					return accessRef.wrapped
				}
			)
		}
	}
}
