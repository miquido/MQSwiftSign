import Foundation
import XCTest
import MQAssert
import PathKit
import XcodeProj

@testable import MQSwiftSign

final class DependencyTreeBuilderTests: FeatureTests {
    
    override func commonPatches(_ patches: FeaturePatches) {
        super.commonPatches(patches)
        self.addTeardownBlock {
            try? self.xcConfigPath.delete()
        }
    }
    
    func test_givenTarget_shouldCreateDependencyTree() async {
        let target = PBXTarget(name: "TestTarget")
        let dependencyTarget = PBXTarget(name: "DependencyTarget")
        let dependency = PBXTargetDependency(name: dependencyTarget.name, target: dependencyTarget)
        target.dependencies.append(dependency)
        await test(
            DependencyTreeBuilder.live(),
            when: { _ in },
            executing: { (feature: DependencyTreeBuilder) in
                let result = try feature.build(target, "")
                XCTAssertEqual(result.targetName, "TestTarget")
                XCTAssertEqual(result.dependencies.count, 1)
                XCTAssertEqual(result.dependencies[0].targetName, "DependencyTarget")
            }
        )
    }

    func test_targetWithoutConfiguration_shouldHaveEmptyBuildSettings() async {
        let target = PBXTarget(name: "TestTarget")
        await test(
            DependencyTreeBuilder.live(),
            when: { _ in },
            executing: { (feature: DependencyTreeBuilder) in
                let result = try feature.build(target, "")
                XCTAssertTrue(result.settings.isEmpty)
            }
        )
    }

    func test_targetWithConfiguration_shouldHaveBuildSettings() async {
        let target = PBXTarget(name: "TestTarget")
        let configuration = XCBuildConfiguration(name: "TestConfiguration")
        configuration.buildSettings = ["TestSetting": "TestValue"]
        let configurationList = XCConfigurationList(buildConfigurations: [configuration])
        target.buildConfigurationList = configurationList
        await test(
            DependencyTreeBuilder.live(),
            when: { _ in },
            executing: { (feature: DependencyTreeBuilder) in
                let result = try feature.build(target, "TestConfiguration")
                XCTAssertEqual(result.settings as? [String: String], ["TestSetting": "TestValue"])
            }
        )
    }

    func test_givenTargetWithBaseConfig_shouldResolveBuildSettingsAgainstIt() async throws {
        try createXCConfigFile(dictionary: ["APP_NAME_SUFFIX": "appnamesuffix", "SOME_OTHER_SETTING": "SETTING"])
        let target = PBXTarget(name: "TestTarget")
        let xcConfiigFile = PBXFileReference(sourceTree: .absolute, path: "TestConfig.xcconfig")
        let configuration = XCBuildConfiguration(
            name: "TestConfiguration",
            baseConfiguration: xcConfiigFile,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.app.test.$(APP_NAME_SUFFIX)",
                "SOME_SETTING": "$(SOME_OTHER_SETTING)",
            ]
        )
        let configurationList = XCConfigurationList(buildConfigurations: [configuration])
        target.buildConfigurationList = configurationList
        
        await test(
            DependencyTreeBuilder.live(),
            when: { _ in },
            executing: { (feature: DependencyTreeBuilder) in
                let result = try feature.build(target, "TestConfiguration")
                XCTAssertEqual(result.settings["PRODUCT_BUNDLE_IDENTIFIER"] as? String, "com.app.test.appnamesuffix")
                XCTAssertEqual(result.settings["SOME_SETTING"] as? String, "SETTING")
            }
        )
    }
}

private extension DependencyTreeBuilderTests {
    var xcConfigPath: Path {
        Path(FileManager.default.currentDirectoryPath + "/TestConfig.xcconfig")
    }

    func createXCConfigFile(dictionary: [String: Any]) throws {
        let content = dictionary.map { "\($0.key) = \($0.value)" }.joined(separator: "\n")
        try content.data(.utf8).write(to: xcConfigPath.url)
    }
}
