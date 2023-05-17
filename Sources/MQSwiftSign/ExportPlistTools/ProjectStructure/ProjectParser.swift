import Foundation

internal struct ProjectParser {
	private let distributionMethod: DistributionMethod
	private let workspace: WorkspaceFile

	init(options: BuildCommandOptions, distributionMethod: DistributionMethod) {
		self.distributionMethod = distributionMethod
		self.workspace = WorkspaceFile(
			workspacePath: options[.workspacePath],
			projectPath: options[.projectPath],
			schemeRawName: options[.schemeName],
			targetRawName: options[.targetName],
			configurationRawName: options[.configurationName])
	}

	internal func parseProject() throws -> ProjectFile {
		return try workspace.createProjectFile()
	}
}
