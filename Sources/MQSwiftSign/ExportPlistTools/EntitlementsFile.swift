import Foundation
import MQTagged

internal enum EntitlementsPathTag {}
internal typealias EntitlementsPath = Tagged<String, EntitlementsPathTag>

internal enum ICloudContainerEnvironmentTag {}
internal typealias ICloudContainerEnvironment = Tagged<String, ICloudContainerEnvironmentTag>

internal struct EntitlementsFile {
	private var path: EntitlementsPath

	init(path: EntitlementsPath) {
		self.path = path
	}

	internal func getICloudContainerEnvironment() throws -> ICloudContainerEnvironment? {
		let entitlementsFileUrl = try path.createEntitlementsFileUrl()
		guard let contents = NSDictionary(contentsOf: entitlementsFileUrl) as? Dictionary<String, Any> else {
			throw ExportPlistContentCreationFailed.error(
				message: "No file at path",
				hintMessage: "Check if correct entitlements path is provided: \(path.rawValue)")
		}
		let entitlementsContents: EntitlementsFileContents = .init(properties: contents)
		return entitlementsContents.iCloudContainerEnvironment.map { .init(rawValue: $0) }
	}
}

private extension EntitlementsPath {

	func createEntitlementsFileUrl() throws -> URL {
		do {
			return try URL(path: self.rawValue)
		} catch {
			throw
				NoSuchFile.error(
					message: "File not found at given path",
					possibleReasons: [.wrongEntitlementsPath],
					displayableMessage: "File doesn't exist"
				)
				.with(self.rawValue, for: "Entitlements path")
		}
	}
}

private struct EntitlementsFileContents {
	private(set) var iCloudContainerEnvironment: String?

	init(properties: Dictionary<String, Any>) {
		self.iCloudContainerEnvironment =
			properties["com.apple.developer.icloud-container-environment"] as? String
	}
}
