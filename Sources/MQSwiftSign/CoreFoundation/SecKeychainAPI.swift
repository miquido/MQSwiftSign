import Foundation
import MQDo

struct SecKeychainAPI {
	var get: (String) -> CFWrapper<SecKeychain>?
	var create: (String, String) throws -> CFWrapper<SecKeychain>
	var addToSearchList: (CFWrapper<SecKeychain>) throws -> Void
	var setDefaultSettings: (CFWrapper<SecKeychain>) throws -> Void
	var unlock: (CFWrapper<SecKeychain>, String) throws -> Void
	var delete: (CFWrapper<SecKeychain>?) -> Void
	var forceDelete: (CFWrapper<SecKeychain>?) throws -> Void
}

extension SecKeychainAPI: DisposableFeature {
	static var placeholder: SecKeychainAPI {
		SecKeychainAPI(
			get: unimplemented1(),
			create: unimplemented2(),
			addToSearchList: unimplemented1(),
			setDefaultSettings: unimplemented1(),
			unlock: unimplemented2(),
			delete: unimplemented1(),
			forceDelete: unimplemented1()
		)
	}
}

extension SecKeychainAPI {
	static func system() -> FeatureLoader {
		.disposable { features -> SecKeychainAPI in
			let preferences: Preferences = try features.instance()

			func get(_ name: String) -> CFWrapper<SecKeychain>? {
				var keychainRef: SecKeychain?
				SecKeychainOpen(name + ".keychain-db", &keychainRef)
				return keychainRef?.wrapped
			}

			func create(_ name: String, _ password: String) throws -> CFWrapper<SecKeychain> {
				var keychainRef: SecKeychain?

				try SecKeychainCreate(
					name + ".keychain-db",
					UInt32(password.count),
					password,
					false,
					nil,
					&keychainRef
				)
					.onFailThrowing(KeychainCreationFailed.error())

				guard let keychainRef else {
					throw KeychainCreationFailed.error()
				}
				Logger.successInfo("Temporary keychain with name '\(name)' created")
				preferences.set(name, forKey: .keychainName)
				return keychainRef.wrapped
			}

			func addToSearchList(_ keychain: CFWrapper<SecKeychain>) throws {
				let error = KeychainSetPropertiesFailed.error(message: "Fetching keychain search list failed")
				guard let keychain = keychain.value else {
					throw error
				}
				var systemList: CFArray?

				try SecKeychainCopySearchList(&systemList)
					.onFailThrowing(
						error)

				guard var existingKeychains = systemList as? [SecKeychain] else {
					throw error
				}

				existingKeychains.append(keychain)
				try SecKeychainSetSearchList(existingKeychains as CFArray)
					.onFailThrowing(
						KeychainSetPropertiesFailed.error(message: "Keychain addition to search list failed"))
				Logger.successInfo("Temporary keychain added to searchlist.")
			}

			func setDefaultSettings(_ keychain: CFWrapper<SecKeychain>) throws {
				let error = KeychainSetPropertiesFailed.error(message: "Cannot set keychain settings")
				guard let keychain = keychain.value else {
					throw error
				}
				var keychainSettings = SecKeychainSettings(
					version: UInt32(SEC_KEYCHAIN_SETTINGS_VERS1),
					lockOnSleep: false,
					useLockInterval: true,
					lockInterval: 24 * 60 * 60
				)

				try SecKeychainSetSettings(
					keychain,
					&keychainSettings
				)
					.onFailThrowing(error)
				Logger.successInfo("Temporary keychain settings set.")
			}

			func unlock(_ keychain: CFWrapper<SecKeychain>, _ password: String) throws {
				let error = KeychainSetPropertiesFailed.error(message: "Cannot unlock keychain")
				guard let keychain = keychain.value else {
					throw error
				}
				try SecKeychainUnlock(
					keychain,
					UInt32(password.count),
					password,
					true
				)
					.onFailThrowing(error)
				Logger.successInfo("Temporary keychain unlocked.")
			}

			func forceDelete(_ keychain: CFWrapper<SecKeychain>?) throws {
				guard let keychain = keychain?.value else {
					return
				}
				let statusCode = SecKeychainDelete(keychain)
				guard statusCode == errSecSuccess else {
					throw
					KeychainDeletionFailed.error(
							message: "Command 'cleanup' failed - could not delete keychain file"
						)
						.with(statusCode.errorMessage, for: "Error description")
				}
				preferences.remove(.keychainName)
				Logger.successInfo("Temporary keychain found and deleted")
			}

			func delete(_ keychain: CFWrapper<SecKeychain>?) {
				do {
					try forceDelete(keychain)
				} catch {
					// Non-throwing equivalent of forceDelete() method
					Logger.info("No keychain with name found; skipping deletion")
					return
				}
			}

			return SecKeychainAPI(
				get: get,
				create: create,
				addToSearchList: addToSearchList,
				setDefaultSettings: setDefaultSettings,
				unlock: unlock,
				delete: delete,
				forceDelete: forceDelete
			)
		}
	}
}
