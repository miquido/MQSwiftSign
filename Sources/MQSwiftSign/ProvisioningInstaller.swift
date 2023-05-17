import Foundation

internal enum ProvisioningInstaller {}

internal extension ProvisioningInstaller {

	static func install(from directoryPath: String) throws {
		let filesDirUrl = try createProvisioningUrl(path: directoryPath)
		let files = try FileManager.default.contentsOfDirectory(
			at: filesDirUrl, includingPropertiesForKeys: nil)
		let provisioningFiles = files.filter { $0.pathExtension == "mobileprovision" }
		let targetDirectory = FileManager.default.getProvisioningsTargetDirectory()
		for provisioningFile in provisioningFiles {
			let uuid = try provisioningFile.uuidFromFileContent()
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

private extension URL {
	func uuidFromFileContent() throws -> String {
		let fileContent = try String(contentsOf: self, encoding: .isoLatin1)
		guard
			let uuidDictEntry = fileContent.getFirstMatching(
				#"<key>UUID</key>[\n\t]*<string>[-a-fA-F0-9]{36}</string>"#),
			let uuid = uuidDictEntry.getFirstMatching(#"[-a-f0-9]{36}"#)
		else {
			throw MissingProperty.error(message: "Missing UUID in provisioning file")
				.with(
					self.absoluteString, for: "Provisioning file path")
		}
		return uuid
	}

}

extension String {
	/// Searches in the string for matches based on a given regular expression pattern and returns the first one.
	///- Parameter pattern: Regular expression pattern based on which the search will be performed.
	///- Returns: The first found string that matches the given regex. When no matching string was found then returns`nil`.
	fileprivate func getFirstMatching(_ pattern: String) -> String? {
		let regex: NSRegularExpression
		do {
			regex = try NSRegularExpression(pattern: pattern)
		} catch { return nil }

		let contentRange = NSMakeRange(0, count)

		guard let firstMatch = regex.firstMatch(in: self, range: contentRange),
			let matchRange = Range(firstMatch.range, in: self)
		else { return nil }

		return String(self[matchRange])
	}
}
