import MQAssert

@testable import MQSwiftSign

final class ExportPlistCreatorTests: FeatureTests {
	func test_givenExtractedOptions_shouldPassOptionsToWriter() async throws {
		let context = PlistCreator.Context(
			distributionMethod: .development, shellScript: "-project TestProject.xcodeproj -scheme AppWithExtensions")
		await test(
			ExportPlistCreator.loader(),
			context: context,
			executedPrepared: 1,
			when: { patches, executed in
				patches(
					patch: \ExportOptionsWriter.write,
					with: { (exportOptions: ExportOptionsPlist) in
						let options = exportOptions.properties.compactMapValues { $0 as? String }
						XCTAssertEqual(options[.method], "development")
						XCTAssertEqual(options[.signingStyle], "manual")
						XCTAssertEqual(options[.signingCertificate], "Apple Development")
						XCTAssertEqual(options[.teamID], "DEVELOPMENT_TEAM_IDENTIFIER")
						executed()
					}
				)
				patches(
					patch: \ExportOptionsExtractor.extract,
					with: {
						ExportOptionsPlist(properties: [
							.method: "development",
							.signingStyle: "manual",
							.signingCertificate: "Apple Development",
							.teamID: "DEVELOPMENT_TEAM_IDENTIFIER",
						]
						)
					}
				)
			},
			executing: { (feature: PlistCreator) in
				try feature.create()
			}
		)
	}

	func test_givenOptions_shouldConvertToRawTypes() {
		let options = ExportOptionsPlist(properties: [
			.method: "development", .provisioningProfiles: ["App": "Profile"],
		])
		let rawOptions = options.convertKeysToRawTypes()
		XCTAssertEqual(rawOptions["method"] as! String, "development")
		XCTAssertEqual(rawOptions["provisioningProfiles"] as! [String: String], ["App": "Profile"])
	}
}
