import Foundation
import MQTagged

internal enum SchemeNameTag {}
internal typealias SchemeName = Tagged<String, SchemeNameTag>

internal struct SchemeFile {
	private var url: URL

	init(url: URL) {
		self.url = url
	}

	internal func getAppTargetRef() throws -> TargetRef {
		guard let appTargetRef: String = XMLSearcher.targetRefSearcher.search(in: url) else {
			throw ExportPlistContentCreationFailed.error(
				message: "No target ref found for given scheme",
				hintMessage: "Check if correct scheme file location path is provided: \(url.path)")
		}
		return TargetRef(rawValue: appTargetRef)
	}

	internal func prepareConfigurationName(with name: ConfigurationName?) throws -> ConfigurationName {
		guard let configurationName = name else {
			Logger.info(
				"Export plist creator: Did not found -configuration option; using default configuration for 'Archive' action..."
			)
			return try url.getDefaultConfigurationName()
		}
		return configurationName
	}
}

private extension URL {

	func getDefaultConfigurationName() throws -> ConfigurationName {
		guard let defaultConfiguration: String = XMLSearcher.configurationNameSearcher.search(in: self) else {
			throw ExportPlistContentCreationFailed.error(
				message: "No default build configuration was found for 'Archive' action",
				hintMessage: "Check if correct scheme file location path is provided: \(self.path)")
		}
		return ConfigurationName(rawValue: defaultConfiguration)
	}
}
