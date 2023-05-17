import Foundation

extension SecKeychain {

	static func create(_ name: String, _ password: String) throws -> SecKeychain {
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
		Logger.info("Temporary keychain with name '\(name)' created")
		UserDefaults.standard.set(name, forKey: "MQSWIFTSIGN_KEYCHAIN_NAME")
		return keychainRef
	}

	static func get(_ name: String) -> SecKeychain? {
		var keychainRef: SecKeychain?
		SecKeychainOpen(name + ".keychain-db", &keychainRef)
		return keychainRef
	}

	// Settings to prevent locking
	func setDefaultSettings() throws {
		var keychainSettings = SecKeychainSettings(
			version: UInt32(SEC_KEYCHAIN_SETTINGS_VERS1),
			lockOnSleep: false,
			useLockInterval: true,
			lockInterval: 24 * 60 * 60
		)

		try SecKeychainSetSettings(
			self,
			&keychainSettings
		)
		.onFailThrowing(KeychainSetPropertiesFailed.error(message: "Cannot set keychain settings"))
		Logger.info("Temporary keychain settings set.")
	}

	// Force unlock keychain
	func unlock(with password: String) throws {
		try SecKeychainUnlock(
			self,
			UInt32(password.count),
			password,
			true
		)
		.onFailThrowing(KeychainSetPropertiesFailed.error(message: "Cannot unlock keychain"))
		Logger.info("Temporary keychain unlocked.")
	}

	// Deletion
	func delete() {
		do {
			try forceDelete()
		} catch {
			// Non-throwing equivalent of forceDelete() method
			Logger.error(error.asTheError().debugDescription)
			return
		}
	}

	func forceDelete() throws {
		let statusCode = SecKeychainDelete(self)
		guard statusCode == errSecSuccess else {
			throw
				KeychainDeletionFailed.error(
					message: "Command 'cleanup' failed - could not delete keychain file"
				)
				.with(statusCode.errorMessage, for: "Error description")
		}
		UserDefaults.standard.removeObject(forKey: "MQSWIFTSIGN_KEYCHAIN_NAME")
		Logger.info("Temporary keychain found and deleted")
	}

	// Add to searchlist (for keychain to be visible by Xcode - see https://stackoverflow.com/questions/20391911/os-x-keychain-not-visible-to-keychain-access-app-in-mavericks)
	func addToSearchlist() throws {
		var systemList: CFArray?

		try SecKeychainCopySearchList(&systemList)
			.onFailThrowing(
				KeychainSetPropertiesFailed.error(message: "Fetching keychain search list failed"))

		guard var existingKeychains = systemList as? [SecKeychain] else {
			throw KeychainSetPropertiesFailed.error(message: "Fetching keychain search list failed")
		}

		existingKeychains.append(self)
		try SecKeychainSetSearchList(existingKeychains as CFArray)
			.onFailThrowing(
				KeychainSetPropertiesFailed.error(message: "Keychain addition to search list failed"))
		Logger.info("Temporary keychain added to searchlist.")
	}

}
