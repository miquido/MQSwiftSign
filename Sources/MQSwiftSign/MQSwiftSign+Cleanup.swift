import ArgumentParser
import Foundation
import MQDo

extension MQSwiftSign {
	struct Cleanup: ParsableCommand, MQSwiftSignCommand {

		static var configuration: CommandConfiguration {
			CommandConfiguration(commandName: "cleanup")
		}

		func run() throws {
			try run(features)
		}

		func run(_ features: Features) throws {
			let preferences: Preferences = try features.instance()
			let keychainAPI: SecKeychainAPI = try features.instance()
			guard let keychainName = preferences.get(.keychainName) else {
				throw
					KeychainDeletionFailed.error(
						message:
							"Command 'cleanup' cannot be executed because keychain name is missing in system vars - did you forget to execute prepare first?"
					)
			}
			let existingKeychain = keychainAPI.get(keychainName)
			try keychainAPI.forceDelete(existingKeychain)
		}
	}
}
