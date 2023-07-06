import XcodeProj

struct DependencyTree {
	let targetName: String
	let settings: BuildSettings
	let dependencies: [DependencyTree]

	func exportOptionsPlistContent() throws -> ExportOptionsPlist {
		let settings = ConfigurationObjectBuildSettings(properties: settings)
		var options: Dictionary<ExportPlistOption, Any> = [:]
		guard
			let team: DevelopmentTeam = settings.developmentTeam,
			let identity: CodeSignIdentity = settings.codesignIdentity,
			let codesignStyle: CodeSignStyle = settings.codesignStyle
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "Build configuration is incomplete - missing some key properties"
				)
				.with(targetName, for: "Target")
				.with(settings.developmentTeam?.rawValue, for: "Team")
				.with(settings.codesignIdentity?.rawValue, for: "Identity")
				.with(settings.codesignStyle?.rawValue, for: "CodesignStyle")
		}
		options[.teamID] = team.rawValue
		options[.signingStyle] = codesignStyle.rawValue
		options[.signingCertificate] = identity.rawValue
		options[.uploadBitcode] = false
		options[.compileBitcode] = true
		options[.uploadSymbols] = true
		options[.provisioningProfiles] = try provisioningProfileMapping
		options[.iCloudContainerEnvironment] = settings.iCloudContainerEnvironment?.rawValue
		return ExportOptionsPlist(properties: options)
	}

	var allDependencies: [DependencyTree] {
		dependencies.flatMap { [$0] + $0.allDependencies }
	}

	internal var provisioningProfileMapping: Dictionary<String, String> {
		get throws {
			var allSettings: [ConfigurationObjectBuildSettings] = allDependencies.map {
				ConfigurationObjectBuildSettings(properties: $0.settings)
			}
			allSettings.append(ConfigurationObjectBuildSettings(properties: settings))
			return try allSettings.compactMap({ try $0.provisioningProfileSpecifier })
				.reduce(
					into: [String: String]()
				) { partial, next in
					partial[next.bundle.value] = next.provisioning.rawValue
				}
		}
	}
}

extension PBXTarget {
	func dependencyTree(usingConfiguration configurationName: ConfigurationName) -> DependencyTree {
		let dependencyTrees: [DependencyTree]
		dependencyTrees = dependencies.compactMap { dependency -> DependencyTree? in
			dependency.target?.dependencyTree(usingConfiguration: configurationName)
		}
		let buildSettings: BuildSettings
		if let configuration = buildConfigurationList?.configuration(name: configurationName.rawValue) {
			buildSettings = configuration.buildSettings
		} else {
			buildSettings = [:]
		}
		return DependencyTree(targetName: name, settings: buildSettings, dependencies: dependencyTrees)
	}
}
