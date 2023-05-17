import Foundation
import MQTagged

internal enum TargetRefTag {}
internal typealias TargetRef = Tagged<String, TargetRefTag>

internal enum TargetNameTag {}
internal typealias TargetName = Tagged<String, TargetNameTag>

internal struct TargetDependencyObject {
	private(set) var targetRef: TargetRef?

	init(properties: Dictionary<String, Any>) {
		self.targetRef = (properties["target"] as? String).map { .init(rawValue: $0) }
	}
}

internal struct TargetObject {
	private(set) var name: String?
	private(set) var dependencies: [String]
	private(set) var configurationListRef: String?

	init(properties: Dictionary<String, Any>) {
		self.name = properties["name"] as? String
		self.dependencies = properties["dependencies"] as? Array<String> ?? []
		self.configurationListRef = properties["buildConfigurationList"] as? String
	}
}

internal struct TargetDependencyTree {
	private var targetRef: TargetRef
	private var settings: ConfigurationObjectBuildSettings
	private var dependencies: [TargetDependencyTree]

	internal var provisioningProfileMapping: Dictionary<String, String> {
		get throws {
			var allSettings: [ConfigurationObjectBuildSettings] = self.dependencies.map { $0.settings }
			allSettings.append(settings)
			return try allSettings.compactMap({ try $0.provisioningProfileSpecifier })
				.reduce(
					into: [String: String]()
				) { partial, next in
					partial[next.bundle.value] = next.provisioning.rawValue
				}
		}
	}

	init(
		targetRef: TargetRef,
		settings: ConfigurationObjectBuildSettings,
		dependencies: [TargetDependencyTree]
	) {
		self.targetRef = targetRef
		self.settings = settings
		self.dependencies = dependencies
	}

	internal func exportOptionsPlistContent() throws -> ExportOptionsPlist {
		var options: Dictionary<ExportPlistOption, Any> = [:]
		guard let team: DevelopmentTeam = settings.developmentTeam,
			let identity: CodeSignIdentity = settings.codesignIdentity,
			let codesignStyle: CodeSignStyle = settings.codesignStyle
		else {
			throw
				ExportPlistContentCreationFailed.error(
					message: "Build configuration is incomplete - missing some key properties"
				)
				.with(targetRef.rawValue, for: "Target")
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
}
