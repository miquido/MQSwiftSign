import Foundation
import MQTagged

internal struct ProjectFileContents {
	private var projectFileObjects: ProjectFileObjects?
	private var projectObjectRef: String?
	private var projectBuildOptions: ProjectObject?
	private var rootTargetRef: TargetRef?
	private var configurationName: ConfigurationName?

	init(properties: Dictionary<String, Any>) {
		self.projectFileObjects = (properties["objects"] as? Dictionary<String, Any>)
			.map({
				.init(properties: $0)
			})
		self.projectObjectRef = properties["rootObject"] as? String
		self.projectBuildOptions = projectFileObjects?.project(for: projectObjectRef)
	}

	internal mutating func getTargetDependencyTree() throws -> TargetDependencyTree {
		guard let rootTargetRef else {
			throw MissingProperty.error(message: "Target ref isn't found.")
		}
		let dependencies: Set<TargetRef> = try getTargetDependencies(for: rootTargetRef)
		var dependenciesTrees: [TargetDependencyTree] = []
		for targetRef in dependencies {
			dependenciesTrees.append(
				TargetDependencyTree(
					targetRef: targetRef,
					settings: try getBuildConfigurationSettings(for: targetRef),
					dependencies: []))
		}
		return TargetDependencyTree(
			targetRef: rootTargetRef,
			settings: try getBuildConfigurationSettings(for: rootTargetRef),
			dependencies: dependenciesTrees)
	}
}

internal extension ProjectFileContents {

	mutating func setConfigurationName(_ name: ConfigurationName?) throws {
		guard let name else {
			Logger.info(
				"Export plist creator: Did not found -configuration option; using project default configuration..."
			)
			self.configurationName = try getDefaultConfigurationName()
			return
		}
		self.configurationName = name
	}

	mutating func setRootTargetRef(_ targetRef: TargetRef) {
		self.rootTargetRef = targetRef
	}

	mutating func setRootTargetRef(from targetName: TargetName) throws {
		guard let projectBuildOptions: ProjectObject = projectBuildOptions,
			let projectFileObjects: ProjectFileObjects = projectFileObjects,
			let targets: [String] = projectBuildOptions.projectTargetsRefs,
			let appTarget: String = targets.first(where: { ref in
				let targetConfig = projectFileObjects.target(for: .init(rawValue: ref))
				let name = targetConfig?.name
				return name == targetName.rawValue
			})
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "Cannot fetch app target from the project file"
				)
				.with(targetName.rawValue, for: "TargetName")
				.with(projectObjectRef, for: "Project object ref")
		}
		self.rootTargetRef = TargetRef(rawValue: appTarget)
	}
}

private extension ProjectFileContents {

	private func getBuildConfigurationSettings(for ref: TargetRef) throws -> ConfigurationObjectBuildSettings {
		guard let objects: ProjectFileObjects = projectFileObjects,
			let targetOptions: TargetObject = objects.target(for: ref),
			let configurationListRef: String = targetOptions.configurationListRef,
			let configurationName: ConfigurationName = configurationName,
			let buildConfigurationList: ConfigurationListObject = objects.configurationListObject(
				for: configurationListRef),
			let buildConfigurationRefs: [String] = buildConfigurationList.buildConfigurationRefs,
			let properConfigurationRef: String = buildConfigurationRefs.first(where: {
				objects.buildConfigurationObject(for: $0)?.name == configurationName.rawValue
			}),
			let configuration: ConfigurationObject = objects.buildConfigurationObject(
				for: properConfigurationRef),
			let buildSettings: ConfigurationObjectBuildSettings = configuration.buildSettings
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "Cannot find configuration options for specified target"
				)
				.with(ref.rawValue, for: "Target ref")
				.with(configurationName?.rawValue, for: "Configuration name")
		}
		return buildSettings
	}

	private func getTargetDependencies(for ref: TargetRef) throws -> Set<TargetRef> {
		guard let projectFileObjects: ProjectFileObjects = projectFileObjects,
			let targetOptions: TargetObject = projectFileObjects.target(for: ref)
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "Cannot fetch app target from the project file"
				)
				.with(ref.rawValue, for: "Target ref")
		}
		var targetRefDependencies: Set<TargetRef> = Set(
			targetOptions.dependencies.compactMap({
				projectFileObjects.targetDependency(for: $0)?.targetRef
			}))
		for dependency in targetRefDependencies {
			targetRefDependencies = try targetRefDependencies.union(getTargetDependencies(for: dependency))
		}
		return targetRefDependencies
	}

	private func getDefaultConfigurationName() throws -> ConfigurationName {
		guard let projectBuildOptions: ProjectObject = projectBuildOptions,
			let configurationsListRef: String = projectBuildOptions.configurationsListRef,
			let projectFileObjects: ProjectFileObjects = projectFileObjects,
			let configurationListOptions: ConfigurationListObject =
				projectFileObjects.configurationListObject(for: configurationsListRef),
			let defaultConfiguration: String = configurationListOptions.defaultConfigurationName
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "Could not find default configuration name"
				)
				.with(projectBuildOptions?.configurationsListRef, for: "Configuration list ref")
		}
		return ConfigurationName(rawValue: defaultConfiguration)
	}
}

private struct ProjectFileObjects {
	private var properties: Dictionary<String, Any>

	init(properties: Dictionary<String, Any>) {
		self.properties = properties
	}

	fileprivate func project(for ref: String?) -> ProjectObject? {
		guard let ref else { return nil }
		return (properties[ref] as? Dictionary<String, Any>).map({ .init(properties: $0) })
	}

	fileprivate func target(for ref: TargetRef) -> TargetObject? {
		(properties[ref.rawValue] as? Dictionary<String, Any>).map({ .init(properties: $0) })
	}

	fileprivate func targetDependency(for ref: String) -> TargetDependencyObject? {
		(properties[ref] as? Dictionary<String, Any>).map({ .init(properties: $0) })
	}

	fileprivate func configurationListObject(for ref: String) -> ConfigurationListObject? {
		(properties[ref] as? Dictionary<String, Any>).map({ .init(properties: $0) })
	}

	fileprivate func buildConfigurationObject(for ref: String) -> ConfigurationObject? {
		(properties[ref] as? Dictionary<String, Any>).map({ .init(properties: $0) })
	}

	fileprivate func configurationBuildSettings(for ref: String) -> ConfigurationObjectBuildSettings? {
		(properties[ref] as? Dictionary<String, Any>).map({ .init(properties: $0) })
	}
}

internal struct ProjectObject {
	internal var configurationsListRef: String?
	internal var projectTargetsRefs: [String]?

	init(properties: Dictionary<String, Any>) {
		self.configurationsListRef = properties["buildConfigurationList"] as? String
		self.projectTargetsRefs = properties["targets"] as? Array<String>
	}
}
