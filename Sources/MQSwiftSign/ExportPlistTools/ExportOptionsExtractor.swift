import Foundation
import MQDo

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
