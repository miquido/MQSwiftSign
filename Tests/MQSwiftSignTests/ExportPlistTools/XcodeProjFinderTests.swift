import Foundation
import MQAssert
import XcodeProj
@testable import MQSwiftSign

final class XcodeProjFinderTests: FeatureTests {
	func test_givenRequestedConfigurationName_shouldReturnConfigurationName() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			executing: { (feature: XcodeProjFinder) in
				let configurationName = try feature.findConfigurationName(requestedConfigurationName: "Debug")
				XCTAssertEqual(configurationName, "Debug")
			}
		)
	}

	func test_givenNoRequestedConfigurationName_whenRootProjectIsMissing_shouldFail() async {
		let xcodeProj = XcodeProj.sample
		xcodeProj.pbxproj.rootObject = nil
		await test(
			XcodeProjFinder.live(),
			context: xcodeProj,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				try feature.findConfigurationName(requestedConfigurationName: nil)
			}
		)
	}

	func test_givenNoRequestedConfigurationName_whenDefaultConfigurationIsMissing_shouldFail() async {
		let xcodeProj = XcodeProj.sample
		xcodeProj.pbxproj.rootObject?.buildConfigurationList.defaultConfigurationName = nil
		await test(
			XcodeProjFinder.live(),
			context: xcodeProj,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				try feature.findConfigurationName(requestedConfigurationName: nil)
			}
		)
	}

	func test_givenNoRequestedConfigurationName_shouldReturnDefaultConfigurationName() async {
		let xcodeProj = XcodeProj.sample
		xcodeProj.pbxproj.rootObject?.buildConfigurationList.defaultConfigurationName = "Debug"
		await test(
			XcodeProjFinder.live(),
			context: xcodeProj,
			executing: { (feature: XcodeProjFinder) in
				let result = try feature.findConfigurationName(requestedConfigurationName: nil)
				XCTAssertEqual(result, "Debug")
			}
		)
	}

	func test_givenNoSchemeNameProvided_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				try feature.findScheme(named: nil)
			}
		)
	}

	func test_givenSchemeName_whenSchemeIsMissing_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				try feature.findScheme(named: "Test")
			}
		)
	}

	func test_givenSchemeName_whenSchemeExists_shouldReturnScheme() async {
		let xcodeProj = XcodeProj.sample
		let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
		xcodeProj.sharedData?.schemes.append(scheme)
		await test(
			XcodeProjFinder.live(),
			context: xcodeProj,
			executing: { (feature: XcodeProjFinder) in
				let result = try feature.findScheme(named: "Test")
				XCTAssertEqual(result, scheme)
			}
		)
	}

	func test_givenRequestedConfigurationNameInScheme_shouldReturnConfigurationName() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				let configurationName = try feature.findConfigurationName(in: scheme, requestedConfigurationName: "Debug")
				XCTAssertEqual(configurationName, "Debug")
			}
		)
	}

	func test_givenNoRequestedConfigurationName_whenNoDefaultConfigurationInScheme_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				try feature.findConfigurationName(in: scheme, requestedConfigurationName: nil)
			}
		)
	}

	func test_givenNoRequestedConfigurationNameInScheme_shouldReturnDefaultConfigurationName() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				scheme.archiveAction = XCScheme.ArchiveAction(buildConfiguration: "Release", revealArchiveInOrganizer: true)
				let result = try feature.findConfigurationName(in: scheme, requestedConfigurationName: nil)
				XCTAssertEqual(result, "Release")
			}
		)
	}

	func test_givenSchemeWithoutBuildAction_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				try feature.findRootTarget(in: scheme)
			}
		)
	}

	func test_givenSchemeWithoutMatchingBuildableReferences_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				scheme.buildAction = XCScheme.BuildAction(buildActionEntries: [])
				try feature.findRootTarget(in: scheme)
			}
		)
	}

	func test_givenSchemeWithValidBuildableReference_whenTargetIsMissing_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				scheme.buildAction = XCScheme.BuildAction(buildActionEntries: [
					.init(
						buildableReference: .init(
							referencedContainer: "container",
							blueprint: nil,
							buildableName: "TestBuild.app",
							blueprintName: "TestBuildBlueprint"
						),
						buildFor: []
					)
				])
				try feature.findRootTarget(in: scheme)
			}
		)
	}

	func test_givenSchemeWithValidBuildableReference_shouldReturnTarget() async {
		let target = PBXNativeTarget(name: "TestBuild")
		let xcodeProj = XcodeProj.sample
		xcodeProj.pbxproj.add(object: target)
		await test(
			XcodeProjFinder.live(),
			context: xcodeProj,
			executing: { (feature: XcodeProjFinder) in
				let scheme = XCScheme(name: "Test", lastUpgradeVersion: "1.0", version: "1.0")
				scheme.buildAction = XCScheme.BuildAction(buildActionEntries: [
					.init(
						buildableReference: .init(
							referencedContainer: "container",
							blueprint: nil,
							buildableName: "TestBuild.app",
							blueprintName: "TestBuild"
						),
						buildFor: []
					)
				])
				let result = try feature.findRootTarget(in: scheme)
				XCTAssertEqual(result, target)
			}
		)
	}

	func test_givenTargetName_whenTargetIsMissing_shouldFail() async {
		await test(
			XcodeProjFinder.live(),
			context: XcodeProj.sample,
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: XcodeProjFinder) in
				try feature.findTarget("TestBuild")
			}
		)
	}

	func test_givenTargetName_shouldReturnTarget() async {
		let target = PBXNativeTarget(name: "TestBuild")
		let xcodeProj = XcodeProj.sample
		xcodeProj.pbxproj.add(object: target)
		await test(
			XcodeProjFinder.live(),
			context: xcodeProj,
			executing: { (feature: XcodeProjFinder) in
				let result = try feature.findTarget("TestBuild")
				XCTAssertEqual(result, target)
			}
		)
	}
}
