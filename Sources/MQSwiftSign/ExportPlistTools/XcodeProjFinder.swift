import MQDo
import XcodeProj

struct XcodeProjFinder {
	var findConfigurationName: (String?) throws -> ConfigurationName
	var findScheme: (String?) throws -> XCScheme
	var findConfigurationNameInScheme: (XCScheme, String?) throws -> ConfigurationName
	var findRootTarget: (XCScheme) throws -> PBXTarget
	var findTarget: (String) throws -> PBXTarget

	func findConfigurationName(requestedConfigurationName: String?) throws -> ConfigurationName {
		try findConfigurationName(requestedConfigurationName)
	}

	func findConfigurationName(in scheme: XCScheme, requestedConfigurationName: String?) throws -> ConfigurationName {
		try findConfigurationNameInScheme(scheme, requestedConfigurationName)
	}

	func findScheme(named schemeName: String?) throws -> XCScheme {
		try findScheme(schemeName)
	}

	func findRootTarget(in scheme: XCScheme) throws -> PBXTarget {
		try findRootTarget(scheme)
	}
}

extension XcodeProjFinder: DisposableFeature {
	typealias Context = XcodeProj
	static var placeholder: XcodeProjFinder {
		XcodeProjFinder(
			findConfigurationName: unimplemented1(),
			findScheme: unimplemented1(),
			findConfigurationNameInScheme: unimplemented2(),
			findRootTarget: unimplemented1(),
			findTarget: unimplemented1()
		)
	}
}

extension XcodeProjFinder {
	static func live() -> FeatureLoader {
		.disposable { xcodeProj, features -> XcodeProjFinder in
			func findConfigurationName(requestedConfigurationName: String?) throws -> ConfigurationName {
				if let configName = requestedConfigurationName {
					return ConfigurationName(rawValue: configName)
				}
				guard let rootProject = try xcodeProj.pbxproj.rootProject() else {
					throw ExportPlistContentCreationFailed.error(
						message: "Root project not found"
					)
				}
				guard let defaultConfig = rootProject.buildConfigurationList.defaultConfigurationName else {
					throw ExportPlistContentCreationFailed.error(
						message: "Could not find default configuration name"
					)
				}
				return ConfigurationName(rawValue: defaultConfig)
			}

			func findScheme(name: String?) throws -> XCScheme {
				guard let schemeName = name else {
					throw ExportPlistContentCreationFailed.error(
						message: "No scheme name nor target name provided. Cannot generate exportPlist."
					)
				}
				guard let scheme = xcodeProj.sharedData?.schemes.first(where: { $0.name == schemeName }) else {
					throw ExportPlistContentCreationFailed.error(
							message: "Cannot fetch app scheme from the project file"
						)
						.with(schemeName, for: "SchemeName")
				}
				return scheme
			}

			func findConfigurationName(in scheme: XCScheme, requestedConfigurationName: String?) throws -> ConfigurationName {
				guard let configName = requestedConfigurationName ?? scheme.archiveAction?.buildConfiguration else {
					throw ExportPlistContentCreationFailed.error(
						message: "No configuration name provided. Cannot generate exportPlist."
					)
				}
				return ConfigurationName(rawValue: configName)
			}

			func findRootTarget(_ scheme: XCScheme) throws -> PBXTarget {
				guard let rootTargetName = scheme.buildAction?
					.buildActionEntries
					.first(where: { $0.buildableReference.buildableName.hasSuffix(".app") })?
					.buildableReference
					.blueprintName
				else {
					throw ExportPlistContentCreationFailed.error(
							message: "No buildable target name found."
						)
						.with(scheme.name, for: "SchemeName")
				}

				guard let rootTarget = xcodeProj.pbxproj.targets(named: rootTargetName).first
				else {
					throw ExportPlistContentCreationFailed.error(
							message: "Target not found found."
						)
						.with(scheme.name, for: "SchemeName")
						.with(rootTargetName, for: "TargetName")
				}
				return rootTarget
			}

			func findTarget(_ targetName: String) throws -> PBXTarget {
				guard let target = xcodeProj.pbxproj.targets(named: targetName).first else {
					throw
					ExportPlistContentCreationFailed.error(
							message: "Cannot fetch app target from the project file"
						)
						.with(targetName, for: "TargetName")
				}
				return target
			}

			return XcodeProjFinder(
				findConfigurationName: findConfigurationName(requestedConfigurationName:),
				findScheme: findScheme(name:),
				findConfigurationNameInScheme: findConfigurationName(in:requestedConfigurationName:),
				findRootTarget: findRootTarget,
				findTarget: findTarget
			)
		}
	}
}
