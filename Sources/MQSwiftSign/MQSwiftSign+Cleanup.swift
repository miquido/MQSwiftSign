import ArgumentParser
import Foundation

extension MQSwiftSign {
	struct Cleanup: ParsableCommand {

		static var configuration: CommandConfiguration {
			CommandConfiguration(commandName: "cleanup")
		}

		func run() throws {
			guard let keychainName = UserDefaults.standard.string(forKey: "MQSWIFTSIGN_KEYCHAIN_NAME") else {
				throw
					KeychainDeletionFailed.error(
						message:
							"Command 'cleanup' cannot be executed because keychain name is missing in system vars - did you forget to execute prepare first?"
					)
			}
			let existingKeychain = SecKeychain.get(keychainName)
			try existingKeychain?.forceDelete()
		}
	}
}
