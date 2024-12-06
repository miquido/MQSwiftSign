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
    
    func test_givenUnresolvedVairables_thenShouldFailOnValidation() async throws {
        await test(
            XcodeProjOptionsExtractor.live(),
            context: .init(xcodeProj: XcodeProj.sample_xcodeproj, options: [.targetName: "TestTarget"]),
            throws: ExportPlistValidationFailed.self,
            when: { patches in
                patches(
                    patch: \XcodeProjFinder.findTarget,
                    with: always(PBXTarget(name:"TestTarget"))
                )
                patches(
                    patch: \XcodeProjFinder.findConfigurationName,
                    with: always(ConfigurationName("SampleConfiguration"))
                )
                patches(
                    patch: \DependencyTreeBuilder.build,
                    with: { _, _ in self.mockedDependencyTree }
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
    
    var mockedDependencyTree: DependencyTree {
        DependencyTree(targetName: "TestTarget",
                       settings: ["DEVELOPMENT_TEAM":"$(DEVELOPMENT_TEAM)",
                                  "CODE_SIGN_IDENTITY":"$(CODE_SIGN_IDENTITY)",
                                  "CODE_SIGN_STYLE":"Manual"],
                       dependencies: [])
    }
}
