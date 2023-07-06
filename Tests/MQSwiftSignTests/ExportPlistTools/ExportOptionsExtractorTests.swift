import Foundation
import MQAssert
import PathKit
import XcodeProj

@testable import MQSwiftSign

final class ExportOptionsExtractorTests: FeatureTests {
	override func commonPatches(_ patches: FeaturePatches) {
		super.commonPatches(patches)

		self.addTeardownBlock {
			try? XcodeProj.projectTestPath().delete()
			try? XcodeProj.workspaceTestPath().delete()
		}
	}

	func test_givenNoProjectNorWorkspacePath_shouldFail() async {
		await test(
			ExportOptionsExtractor.xcodeProj(),
			context: [:],
			throws: ExportPlistContentCreationFailed.self,
			executing: { (feature: ExportOptionsExtractor) in
				try feature.extract()
			}
		)
	}

	func test_givenInvalidWorkspacePath_shouldFail() async {
		await test(
			ExportOptionsExtractor.xcodeProj(),
			context: [.workspacePath: "InvalidPath"],
			executing: { (feature: ExportOptionsExtractor) in
				do {
					_ = try feature.extract()
					XCTFail("Should fail")
				} catch {
					// expected error
				}
			}
		)
	}

	func test_givenInvalidProjectPath_shouldFail() async {
		await test(
			ExportOptionsExtractor.xcodeProj(),
			context: [.projectPath: "InvalidPath"],
			executing: { (feature: ExportOptionsExtractor) in
				do {
					_ = try feature.extract()
					XCTFail("Should fail")
				} catch {
					// expected error
				}
			}
		)
	}

	func test_givenValidWorkspacePath_shouldReturnExportOptions() async throws {
		try XcodeProj.sample_xcworkspace.write(path: XcodeProj.workspaceTestPath())
		try XcodeProj.sample_xcodeproj.write(path: XcodeProj.projectTestPath())
		await test(
			ExportOptionsExtractor.xcodeProj(),
			context: [.workspacePath: XcodeProj.workspaceTestPath().string],
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \XcodeProjOptionsExtractor.extract,
					with: {
						executed()
						return ExportOptionsPlist(properties: [.method: "app-store"])
					}
				)
			},
			executing: { (feature: ExportOptionsExtractor) in
				let options = try feature.extract()
				XCTAssertEqual(options.properties[.method] as? String, "app-store")
			}
		)
	}

	func test_givenValidProjectPath_shouldReturnExportOptions() async throws {
		try XcodeProj.sample_xcodeproj.write(path: XcodeProj.projectTestPath())
		await test(
			ExportOptionsExtractor.xcodeProj(),
			context: [.projectPath: XcodeProj.projectTestPath().string],
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \XcodeProjOptionsExtractor.extract,
					with: {
						executed()
						return ExportOptionsPlist(properties: [.method: "development"])
					}
				)
			},
			executing: { (feature: ExportOptionsExtractor) in
				let options = try feature.extract()
				XCTAssertEqual(options.properties[.method] as? String, "development")
			}
		)
	}
}
