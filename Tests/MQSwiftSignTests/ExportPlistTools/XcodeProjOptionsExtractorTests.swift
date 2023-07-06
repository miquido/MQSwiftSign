import MQAssert
import XcodeProj

@testable import MQSwiftSign

final class XcodeProjExportOptionsExtractorTests: FeatureTests {
	func test_schemeNotFound_shouldFailWithError() async {
		await test(
			XcodeProjOptionsExtractor.live(),
			context: .init(xcodeProj: XcodeProj.sample_xcodeproj, options: [:]),
			throws: ExportPlistContentCreationFailed.self,
			when: { patches in
				patches(
					patch: \XcodeProjFinder.findScheme,
					with: alwaysThrowing(ExportPlistContentCreationFailed.error())
				)
			},
			executing: { (feature: XcodeProjOptionsExtractor) in
				try feature.extract()
			}
		)
	}

	func test_givenInvalidTarget_thenShouldFailWithError() async {
		await test(
			XcodeProjOptionsExtractor.live(),
			context: .init(xcodeProj: XcodeProj.sample_xcodeproj, options: [.targetName: "InvalidTarget"]),
			throws: ExportPlistContentCreationFailed.self,
			when: { patches in
				patches(
					patch: \XcodeProjFinder.findTarget,
					with: alwaysThrowing(ExportPlistContentCreationFailed.error())
				)
			},
			executing: { (feature: XcodeProjOptionsExtractor) in
				try feature.extract()
			}
		)
	}

	func test_givenNoConfigurationNameProvided_whenThereIsNoDefaultConfiguration_thenShouldFailWithError() async throws
	{
		await test(
			XcodeProjOptionsExtractor.live(),
			context: .init(xcodeProj: XcodeProj.sample_xcodeproj, options: [.targetName: "WatchApp"]),
			throws: ExportPlistContentCreationFailed.self,
			when: { patches in
				patches(
					patch: \XcodeProjFinder.findTarget,
					with: { _ in self.mockedTarget }
				)
				patches(
					patch: \XcodeProjFinder.findConfigurationName,
					with: alwaysThrowing(ExportPlistContentCreationFailed.error())
				)
			},
			executing: { (feature: XcodeProjOptionsExtractor) in
				try feature.extract()
			}
		)
	}
}

private extension XcodeProjExportOptionsExtractorTests {
	var mockedTarget: PBXTarget {
		PBXTarget(name: "Test")
	}
}
