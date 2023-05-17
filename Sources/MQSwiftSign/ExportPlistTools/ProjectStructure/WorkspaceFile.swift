import Foundation
import MQTagged

internal enum WorkspacePathTag {}
internal typealias WorkspacePath = Tagged<String, WorkspacePathTag>

internal struct WorkspaceFile {
	private let workspacePath: WorkspacePath?
	private let projectPath: ProjectPath?
	private let schemeName: SchemeName?
	private let targetName: TargetName?
	private let configurationName: ConfigurationName?

	init(
		workspacePath: String?,
		projectPath: String?,
		schemeRawName: String?,
		targetRawName: String?,
		configurationRawName: String?
	) {
		self.workspacePath = workspacePath.map({ WorkspacePath(rawValue: $0) })
		self.projectPath = projectPath.map({ ProjectPath(rawValue: $0) })
		self.schemeName = schemeRawName.map({ SchemeName(rawValue: $0) })
		self.targetName = targetRawName.map({ TargetName(rawValue: $0) })
		self.configurationName = configurationRawName.map({ ConfigurationName(rawValue: $0) })
	}

	internal func createProjectFile() throws -> ProjectFile {
		guard let workspacePath else {
			return try createProjectFile(from: projectPath)
		}
		let projectFilePath: ProjectPath = try workspacePath.getProjectFilePathFromWorkspace()
		guard let schemeName else {
			throw ExportPlistContentCreationFailed.error(
				message:
					"No scheme param provided - you have to provide -scheme param for -workspace option"
			)
		}
		return ProjectFile(
			projectPath: projectFilePath,
			targetName: nil,
			schemeName: schemeName,
			configurationName: configurationName)
	}
}

private extension WorkspaceFile {

	private func createProjectFile(from projectPath: ProjectPath?) throws -> ProjectFile {
		guard let projectPath else {
			throw ExportPlistContentCreationFailed.error(
				message:
					"No -workspace nor -project options were provided in build command. ExportPlist generator cannot proceed."
			)
		}
		Logger.info("Export plist creator: -workspace option not provided. Will go with -project...")
		guard let schemeName else {
			guard let targetName else {
				throw ExportPlistContentCreationFailed.error(
					message: "No scheme name nor target name provided. Cannot generate exportPlist."
				)
			}
			return ProjectFile(
				projectPath: projectPath,
				targetName: targetName,
				schemeName: nil,
				configurationName: configurationName)
		}
		return ProjectFile(
			projectPath: projectPath,
			targetName: nil,
			schemeName: schemeName,
			configurationName: configurationName)
	}
}

private extension WorkspacePath {

	func createWorkspaceUrl() throws -> URL {
		do {
			return try URL(path: self.rawValue)
		} catch {
			throw
				NoSuchFile.error(
					message: "File not found at given path",
					possibleReasons: [.wrongWorkspacePath],
					displayableMessage: "File doesn't exist"
				)
				.with(self.rawValue, for: "Workspace path")
		}
	}

	func getProjectFilePathFromWorkspace() throws -> ProjectPath {
		let workspaceUrl: URL = try createWorkspaceUrl()
		let relativePath: URL = workspaceUrl.deletingLastPathComponent()
		guard
			let projectFilePath: ProjectPath = XMLSearcher
				.projectFileSearcher
				.search(in: workspaceUrl.appendingPathComponent("/contents.xcworkspacedata"))
				.map(
					{ ProjectPath(rawValue: relativePath.path + "/" + $0) })
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "No project file reference in workspace",
					hintMessage: "Check if correct workspace path is provided: \(self.rawValue)"
				)
				.with(workspaceUrl, for: "Workspace url")
		}
		return projectFilePath
	}
}
