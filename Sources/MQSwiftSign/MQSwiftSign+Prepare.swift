import ArgumentParser
import CryptoKit
import Foundation

extension MQSwiftSign {
	struct PrepareOptions: ParsableArguments {
		@Argument(
			help: "Base64 encoded certificate content. You can get one by calling `cat <cert_file>.p12 | base64`.")
		fileprivate var certContent: String

		@Option(
			name: .long,
			help:
				"Password to decrypt certificate. This is the same password you have used to export certificate from your keychain. Empty string by default."
		)
		fileprivate var certPassword: String?

		@Option(
			name: .long,
			help: "Temporary keychain name. If not provided, the tool will use name derived from certificate.")
		fileprivate var keychainName: String?

		@Option(
			name: .long,
			help: "Temporary keychain password. If not provided, the tool will use random generated, 15 characters long string.")
		fileprivate var keychainPassword: String?

		@Option(name: .long, help: "Relative path to a directory which contains provisioning profiles to be installed.")
		fileprivate var provisioningPath: String?

		@Option(
			name: .long, parsing: .upToNextOption,
			help: "Custom ACL groups/partitions to which access to keychain item will be granted.")
		fileprivate var customAcls: [String] = []

		@Option(
			name: .long, parsing: .upToNextOption,
			help: "Absolute paths to apps that are allowed access to the keychain item without user confirmation.")
		fileprivate var applications: [String] = []
	}
}

extension MQSwiftSign {
	struct Prepare: ParsableCommand {

		static var configuration: CommandConfiguration {
			CommandConfiguration(commandName: "prepare")
		}

		@OptionGroup private var prepareOptions: PrepareOptions

		init() {}

		init(prepareOptions: PrepareOptions) {
			self.prepareOptions = prepareOptions
		}

		mutating func run() throws {
			guard let decodedCert = Data(base64Encoded: prepareOptions.certContent) else {
				throw InvalidCertificate.error(message: "Certificate is not valid base64")
			}
			let certPassword = self.prepareOptions.certPassword ?? ""
			let keychainName =
				self.prepareOptions.keychainName ?? calculateSHAHash(for: String(prepareOptions.certContent.prefix(10)))
			let keychainPassword = self.prepareOptions.keychainPassword ?? randomString(length: 15)
			let keychain = try Keychain(keychainName: keychainName, keychainPassword: keychainPassword)
			try keychain.import(decodedCert, using: certPassword, for: prepareOptions.applications)
			try keychain.setACLs(using: keychainPassword, with: prepareOptions.customAcls)
			if let provisioningPath = self.prepareOptions.provisioningPath {
				Logger.info("Detected provisioning file path at \(provisioningPath). Installing...")
				try ProvisioningInstaller.install(from: provisioningPath)
			}
		}

	}
}

func randomString(length: Int) -> String {
	let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	return String((0..<length).compactMap { _ in chars.randomElement() })
}

func calculateSHAHash(for text: String) -> String {
	let inputData = Data(text.utf8)
	let hashed = SHA512.hash(data: inputData)
	return String(hashed.compactMap { String(format: "%02x", $0) }.joined().prefix(10))
}
