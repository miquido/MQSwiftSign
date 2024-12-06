import Foundation
import MQDo
import XcodeProj

struct ExportOptionsExtractor {
	var extract: () throws -> ExportOptionsPlist
}

extension ExportOptionsExtractor: DisposableFeature {
	typealias Context = BuildCommandOptions
	static var placeholder: ExportOptionsExtractor {
		ExportOptionsExtractor(
			extract: unimplemented0()
		)
	}
}

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
