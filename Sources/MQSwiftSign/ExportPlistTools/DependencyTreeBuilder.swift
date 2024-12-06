import Foundation
import MQDo
import PathKit
import XcodeProj

struct DependencyTreeBuilder {
	var build: (PBXTarget, ConfigurationName) throws -> DependencyTree
}

extension DependencyTreeBuilder: DisposableFeature {
	static var placeholder: DependencyTreeBuilder {
		DependencyTreeBuilder(
			build: unimplemented2()
		)
	}
}

extension DependencyTreeBuilder {
	static func live() -> FeatureLoader {
		.disposable { fetaures in
			func buildTree(for target: PBXTarget, using configurationName: ConfigurationName) throws -> DependencyTree {
				let dependencyTrees: [DependencyTree]
				dependencyTrees = try target.dependencies.compactMap { dependency -> DependencyTree? in
					guard let target = dependency.target else { return nil }
					return try buildTree(for: target, using: configurationName)
				}
				let buildSettings: BuildSettings
				if let configuration = target.buildConfigurationList?
					.configuration(name: configurationName.rawValue)
				{
					if let xcConfigFile = try? configuration.baseConfiguration?.xcConfigFile() {
						buildSettings = configuration.buildSettings.resolveUsing(other: xcConfigFile.buildSettings)
					} else {
						buildSettings = configuration.buildSettings
					}
				} else {
					buildSettings = [:]
				}
				return DependencyTree(targetName: target.name, settings: buildSettings, dependencies: dependencyTrees)
			}

			return DependencyTreeBuilder(
				build: { target, configurationName in
					try buildTree(for: target, using: configurationName)
				}
			)
		}
	}
}

private extension PBXFileReference {
	func xcConfigFile() throws -> XCConfig? {
		return try fullPath(sourceRoot: "").flatMap { try? XCConfig(path: Path($0)) }
	}
}

private extension BuildSettings {
	func resolveUsing(other settings: BuildSettings) -> BuildSettings {
		return self.mapValues { value in
			(value as? String)?.replaceValue(using: settings) ?? value
		}
	}
}

private extension String {
	func replaceValue(using other: BuildSettings) -> String {
		let regex = try? NSRegularExpression(pattern: #"\$\((.*?)\)"#, options: [])
		let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) ?? []

		return matches.reduce(self) { resolvedValue, match in
			guard let range = Range(match.range(at: 1), in: self) else { return resolvedValue }
			let variableName = String(self[range])
			let replacement = other[variableName] as? String ?? "$(\(variableName))"
			return resolvedValue.replacingOccurrences(of: "$(\(variableName))", with: replacement)
		}
	}
}
