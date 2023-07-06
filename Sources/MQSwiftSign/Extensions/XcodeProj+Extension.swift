import Foundation
import PathKit
import XcodeProj

extension XcodeProj {

	convenience init(workspacePath string: String) throws {
		let workspace = try XCWorkspace(pathString: string)
		guard let projectPath = workspace.data.children.first?.location.path else {
			throw
				MissingProperty
				.error(message: "Xcworkspace file is missing a project path")
				.with(string, for: "Workspace file")
		}

		try self.init(pathString: projectPath)
	}

}
