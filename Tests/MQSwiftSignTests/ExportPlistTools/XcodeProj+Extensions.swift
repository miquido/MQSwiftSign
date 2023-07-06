import PathKit
import XcodeProj

extension XcodeProj {
	static var sample_xcodeproj: XcodeProj {
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
		return XcodeProj(workspace: workspace, pbxproj: pbxproj, sharedData: sharedData)
	}

	static var sample_xcworkspace: XCWorkspace {
		let workspace = XCWorkspace()
		workspace.data.children = [
			.file(.init(location: .group(projectTestPath().string))),
			.file(.init(location: .group("Pods/Pods.xcodeproj"))),
		]
		return workspace
	}

	static func pathForTest() -> Path {
		Path(#file).parent()
	}

	static func projectFileName() -> String {
		"TestProject.xcodeproj"
	}

	static func projectTestPath() -> Path {
		pathForTest() + projectFileName()
	}

	static func workspaceFileName() -> String {
		"TestWorkspace.xcworkspace"
	}

	static func workspaceTestPath() -> Path {
		pathForTest() + workspaceFileName()
	}
}
