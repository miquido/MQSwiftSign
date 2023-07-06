import Foundation
import MQDo
import RegexBuilder

internal struct ProvisioningInstaller {
	var install: (String, FileSearcher) throws -> Void
}

internal extension ProvisioningInstaller {
	func install(from directoryPath: String, using uuidSearcher: FileSearcher) throws {
		try install(directoryPath, uuidSearcher)
	}

	private func createProvisioningUrl(path: String) throws -> URL {
		do {
			let currentDirectory = FileManager.default.currentDirectoryPath
			return try URL(path: currentDirectory + "/\(path)")
		} catch {
			throw
				NoSuchFile.error(
					message: "File not found at given path",
					possibleReasons: [.wrongProvisioningPath],
					displayableMessage: "File doesn't exist"
				)
				.with(path, for: "Provisioning path")
		}
	}
}

extension ProvisioningInstaller: DisposableFeature {
	static var placeholder: ProvisioningInstaller {
		ProvisioningInstaller(
			install: unimplemented2()
		)
	}
}

extension ProvisioningInstaller {
	static func system() -> FeatureLoader {
		.disposable { _ in
			ProvisioningInstaller(
				install: { directoryPath, uuidSearcher in
					let filesDirUrl = try createProvisioningUrl(path: directoryPath)
					let files = try FileManager.default.contentsOfDirectory(
						at: filesDirUrl, includingPropertiesForKeys: nil)
					let provisioningFiles = files.filter {
						$0.pathExtension == "mobileprovision"
					}
					let targetDirectory = FileManager.default.getProvisioningsTargetDirectory()
					for provisioningFile in provisioningFiles {
						let uuid = try uuidSearcher.search(in: provisioningFile)
						let targetFilePath = targetDirectory + uuid + ".mobileprovision"
						try FileManager.default.createDirIfNotExists(targetDirectory)
						try FileManager.default.removeFileIfExist(at: targetFilePath)
						try FileManager.default.copyItem(at: provisioningFile, to: URL(fileURLWithPath: targetFilePath))
						Logger.info("Found and installed provisioning profile \(provisioningFile) with UUID: \(uuid)")
					}
				}
			)
		}
	}
}

internal extension ProvisioningInstaller {

	static func install(from directoryPath: String, using uuidSearcher: FileSearcher) throws {
		let filesDirUrl = try createProvisioningUrl(path: directoryPath)
		let files = try FileManager.default.contentsOfDirectory(
			at: filesDirUrl, includingPropertiesForKeys: nil)
		let provisioningFiles = files.filter { $0.pathExtension == "mobileprovision" }
		let targetDirectory = FileManager.default.getProvisioningsTargetDirectory()
		for provisioningFile in provisioningFiles {
			let uuid = try uuidSearcher.search(in: provisioningFile)
			let targetFilePath = targetDirectory + uuid + ".mobileprovision"
			try FileManager.default.createDirIfNotExists(targetDirectory)
			try FileManager.default.removeFileIfExist(at: targetFilePath)
			try FileManager.default.copyItem(at: provisioningFile, to: URL(fileURLWithPath: targetFilePath))
			Logger.info("Found and installed provisioning profile \(provisioningFile) with UUID: \(uuid)")
		}
	}

	static private func createProvisioningUrl(path: String) throws -> URL {
		do {
			let currentDirectory = FileManager.default.currentDirectoryPath
			return try URL(path: currentDirectory + "/\(path)")
		} catch {
			throw
				NoSuchFile.error(
					message: "File not found at given path",
					possibleReasons: [.wrongProvisioningPath],
					displayableMessage: "File doesn't exist"
				)
				.with(path, for: "Provisioning path")
		}
	}

}

private extension FileManager {

	func getProvisioningsTargetDirectory() -> String {
		let homeDirectory = homeDirectoryForCurrentUser.path
		return "\(homeDirectory)/Library/MobileDevice/Provisioning Profiles/"
	}

	func removeFileIfExist(at path: String) throws {
		if fileExists(atPath: path) {
			try removeItem(atPath: path)
		}
	}
}

protocol FileSearcher {
	func search(in file: URL) throws -> String
}

struct UUIDSearcher: FileSearcher {

	private let regexp = Regex {
		"<key>UUID</key>"
		OneOrMore(CharacterClass(.whitespace, .anyOf("\n\t")))
		"<string>"
		Capture {
			Repeat(CharacterClass(.hexDigit, .anyOf("-")), count: 36)
		} transform: {
			String($0)
		}
		"</string>"
	}

	func search(in file: URL) throws -> String {
		let fileContent: String = try String(contentsOf: file, encoding: .isoLatin1)
		guard let (_, uuid) = fileContent.firstMatch(of: regexp)?.output else {
			throw MissingProperty.error(message: "Missing UUID in provisioning file")
				.with(
					file.absoluteString, for: "Provisioning file path")
		}
		return String(uuid)
	}
}
