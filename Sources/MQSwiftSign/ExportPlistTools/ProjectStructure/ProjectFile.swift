import Foundation
import MQTagged

internal enum ProjectPathTag {}
internal typealias ProjectPath = Tagged<String, ProjectPathTag>

internal struct ProjectFile {
	private let projectPath: ProjectPath
	private let targetName: TargetName?
	private let schemeName: SchemeName?
	private var configurationName: ConfigurationName?

	init(
		projectPath: ProjectPath,
		targetName: TargetName?,
		schemeName: SchemeName?,
		configurationName: ConfigurationName?
	) {
		self.projectPath = projectPath
		self.targetName = targetName
		self.schemeName = schemeName
		self.configurationName = configurationName
	}

	internal func prepareTargetDependencyTree() throws -> TargetDependencyTree {
		var projectContents: ProjectFileContents = try projectPath.createProjectFileUrl().getFileContents()
		if let targetName {
			try projectContents.setRootTargetRef(from: targetName)
			try projectContents.setConfigurationName(configurationName)
		} else {
			guard let schemeName else {
				throw MissingProperty.error(
					message:
						"No -target nor -scheme options were provided in build command. Cannot parse project file."
				)
			}
			let schemeFileURL: URL = try projectPath.createSchemeFileUrl(schemeName: schemeName)
			let schemeFile: SchemeFile = SchemeFile(url: schemeFileURL)
			projectContents.setRootTargetRef(try schemeFile.getAppTargetRef())
			try projectContents.setConfigurationName(
				try schemeFile.prepareConfigurationName(with: configurationName))
		}
		return try projectContents.getTargetDependencyTree()
	}
}

private extension ProjectPath {

	func createProjectFileUrl() throws -> URL {
		let projectFileLocation: String = self.rawValue + "/project.pbxproj"
		do {
			return try URL(path: projectFileLocation)
		} catch {
			throw
				NoSuchFile.error(
					message: "File not found at given path",
					possibleReasons: [.wrongProjectPath],
					displayableMessage: "File doesn't exist"
				)
				.with(self.rawValue, for: "Project path")
		}
	}

	func createSchemeFileUrl(schemeName: SchemeName) throws -> URL {
		let schemeFileLocation: String = self.rawValue + "/xcshareddata/xcschemes/\(schemeName).xcscheme"
		do {
			return try URL(path: schemeFileLocation)
		} catch {
			throw
				NoSuchFile.error(
					message: "File not found at given path",
					possibleReasons: [.wrongProjectPath, .wrongSchemeName],
					displayableMessage: "File doesn't exist"
				)
				.with(self.rawValue, for: "Project path")
				.with(schemeName.rawValue, for: "Scheme name")
		}
	}
}

private extension URL {

	func getFileContents() throws -> ProjectFileContents {
		guard let contents = NSDictionary(contentsOf: self) as? Dictionary<String, Any> else {
			throw NoSuchFile.error(message: "No file at path", possibleReasons: [.wrongProjectPath])
				.with(
					self, for: "File location path")
		}
		return ProjectFileContents(properties: contents)
	}
}
