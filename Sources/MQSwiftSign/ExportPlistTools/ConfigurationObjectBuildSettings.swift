import Foundation
import MQTagged
import RegexBuilder

internal enum ConfigurationNameTag {}
internal typealias ConfigurationName = Tagged<String, ConfigurationNameTag>

internal enum ProvisioningProfileSpecifierTag {}
internal typealias ProvisioningProfileSpecifier = Tagged<String, ProvisioningProfileSpecifierTag>

internal enum DevelopmentTeamTag {}
internal typealias DevelopmentTeam = Tagged<String, DevelopmentTeamTag>

internal enum CodeSignIdentityTag {}
internal typealias CodeSignIdentity = Tagged<String, CodeSignIdentityTag>

internal enum CodeSignStyleTag {}
internal typealias CodeSignStyle = Tagged<String, CodeSignStyleTag>

internal struct BundleID: PatternValidator {
	var pattern: Regex<Substring> = Regex {
		OneOrMore(CharacterClass(.word, .digit, .anyOf("_\\.")))
	}
	var value: String
}

internal struct ConfigurationObjectBuildSettings {
	private var bundleId: String?
	private var genericSpecifier: String?
	private var platformSpecifier: String?
	private var genericDevelopmentTeam: String?
	private var platformDevelopmentTeam: String?
	private var genericIdentity: String?
	private var platformIdentity: String?
	private var codeSigningStyle: String?
	private var codeSigningEntitlements: String?

	init(properties: Dictionary<String, Any>, platform: String? = nil) {
		self.bundleId = properties["PRODUCT_BUNDLE_IDENTIFIER"] as? String
		self.genericSpecifier = (properties["PROVISIONING_PROFILE_SPECIFIER"] as? String).nilIfEmpty
		self.platformSpecifier =
			properties["PROVISIONING_PROFILE_SPECIFIER[sdk=\(platform ?? "iphoneos")*]"] as? String
		self.genericDevelopmentTeam = (properties["DEVELOPMENT_TEAM"] as? String).nilIfEmpty
		self.platformDevelopmentTeam = (properties["DEVELOPMENT_TEAM[sdk=\(platform ?? "iphoneos")*]"] as? String).nilIfEmpty
		self.genericIdentity = (properties["CODE_SIGN_IDENTITY"] as? String).nilIfEmpty
		self.platformIdentity = (properties["CODE_SIGN_IDENTITY[sdk=\(platform ?? "iphoneos")*]"] as? String).nilIfEmpty
		self.codeSigningStyle = (properties["CODE_SIGN_STYLE"] as? String ?? "Manual")?.lowercased()
		self.codeSigningEntitlements = properties["CODE_SIGN_ENTITLEMENTS"] as? String
	}
}

internal extension ConfigurationObjectBuildSettings {

	var provisioningProfileSpecifier: (bundle: BundleID, provisioning: ProvisioningProfileSpecifier)? {
		get throws {
			guard let bundleIdValue: String = bundleId,
				let profileSpecifier: String = genericSpecifier ?? platformSpecifier,
				!profileSpecifier.isEmpty
			else {
				return nil
			}

			let bundleId = BundleID(value: bundleIdValue)
			if !bundleId.isValid() {
				throw InvalidBundleID.error(message: "Bundle ID seems to be not valid")
					.with(
						bundleIdValue, for: "BundleID")
			}
			return (bundleId, ProvisioningProfileSpecifier(rawValue: profileSpecifier))
		}
	}

	var developmentTeam: DevelopmentTeam? {
		return (platformDevelopmentTeam ?? genericDevelopmentTeam).map({ .init(rawValue: $0) })
	}

	var codesignIdentity: CodeSignIdentity? {
		return (platformIdentity ?? genericIdentity).map({ .init(rawValue: $0) })
	}

	var codesignStyle: CodeSignStyle? {
		return codeSigningStyle.map({ .init(rawValue: $0) })
	}

	var iCloudContainerEnvironment: ICloudContainerEnvironment? {
		guard let path: EntitlementsPath = codeSigningEntitlements.map({ EntitlementsPath(rawValue: $0) }),
			let iCloudContainerEnvironment: ICloudContainerEnvironment = try? EntitlementsFile(path: path)
				.getICloudContainerEnvironment()
		else {
			Logger.warning(
				"iCloudContainerEnvironment was not found. If you use CloudKit in your project, please provide this property in .entitlements file. In case not using CloudKit, the warning can be safely omitted."
			)
			return nil
		}
		return iCloudContainerEnvironment
	}
}

fileprivate extension Optional where Wrapped == String {
	var nilIfEmpty: String? {
		guard let strongSelf = self else {
			return nil
		}
		return strongSelf.isEmpty ? nil : strongSelf
	}
}
