import XcodeProj
import PathKit

extension XcodeProj {
	static var sample: XcodeProj {
		let workspace = XCWorkspace()
		let configurationList = XCConfigurationList(buildConfigurations: [])
		let mainGroup = PBXGroup(children: [])
		let rootObject = PBXProject(
			name: "Test",
			buildConfigurationList: configurationList,
			compatibilityVersion: "Xcode 9.3",
			mainGroup: mainGroup
		)

		let pbxproj = PBXProj(rootObject: rootObject, objects: [rootObject, mainGroup, configurationList])
		let sharedData = XCSharedData(schemes: [])
		return try! XcodeProj(workspace: workspace, pbxproj: pbxproj, sharedData: sharedData)
	}

	func write(atProjectPath path: Path) {
		try! write(path: path, override: true)
	}

	func write(atWorkspacePath path: Path) {
		try! workspace.write(path: path)
		try! pbxproj.write(path: path + "project.pbxproj", override: true)
	}
}
