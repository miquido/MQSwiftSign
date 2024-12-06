import Foundation
import MQDo
import XcodeProj

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
                let dependencyTreeBuilder: DependencyTreeBuilder = try features.instance()
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

                let dependencyTree = try dependencyTreeBuilder.build(target, configurationName)
				let exportPlist = try dependencyTree.exportOptionsPlistContent()
                try exportPlist.validate()
                return exportPlist
			}

			return XcodeProjOptionsExtractor(
				extract: extract
			)
		}
	}
}
