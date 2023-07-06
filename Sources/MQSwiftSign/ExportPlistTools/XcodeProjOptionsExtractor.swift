import Foundation
import MQDo
import XcodeProj

extension ExportOptionsExtractor {
	static func xcodeProj() -> FeatureLoader {
		.disposable { buildOptions, features in
			ExportOptionsExtractor(
				extract: {
					let projectPath: String? = buildOptions[.projectPath]
					let workspacePath: String? = buildOptions[.workspacePath]
					let xcodeProj: XcodeProj
					if let pPath = projectPath {
						xcodeProj = try XcodeProj(pathString: pPath)
					} else if let wPath = workspacePath {
						xcodeProj = try XcodeProj(workspacePath: wPath)
					} else {
						throw ExportPlistContentCreationFailed.error(
							message:
								"No -workspace nor -project options were provided in build command. ExportPlist generator cannot proceed."
						)
					}
					let extractor: XcodeProjOptionsExtractor = try features.instance(
						context: .init(xcodeProj: xcodeProj, options: buildOptions))
					return try extractor.extract()
				}
			)
		}
	}
}

struct XcodeProjOptionsExtractor {
	var extract: () throws -> ExportOptionsPlist

	struct Context {
		var xcodeProj: XcodeProj
		var options: BuildCommandOptions
	}
}

extension XcodeProjOptionsExtractor: DisposableFeature {
	static var placeholder: XcodeProjOptionsExtractor {
		XcodeProjOptionsExtractor(
			extract: unimplemented0()
		)
	}
}

extension XcodeProjOptionsExtractor {
	static func live() -> FeatureLoader {
		.disposable { context, features -> XcodeProjOptionsExtractor in
			func extract() throws -> ExportOptionsPlist {
				let worker: XcodeProjFinder = try features.instance(context: context.xcodeProj)
				let target: PBXTarget
				let configurationName: ConfigurationName

				if let targetName = context.options[.targetName] {
					target = try worker.findTarget(targetName)
					configurationName = try worker.findConfigurationName(context.options[.configurationName])
				} else {
					let scheme = try worker.findScheme(context.options[.schemeName])
					configurationName = try worker.findConfigurationName(
						in: scheme, requestedConfigurationName: context.options[.configurationName])
					target = try worker.findRootTarget(in: scheme)
				}

				let dependencyTree = target.dependencyTree(usingConfiguration: configurationName)
				return try dependencyTree.exportOptionsPlistContent()
			}

			return XcodeProjOptionsExtractor(
				extract: extract
			)
		}
	}
}
