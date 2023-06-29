import Foundation
import MQDo
import MQTagged

typealias ExportPath = Tagged<String, ExportOptionsWriter>

struct ExportOptionsWriter {
	var write: (ExportOptionsPlist) throws -> Void
}

extension ExportOptionsWriter {
	typealias Context = ExportPath

	func write(_ content: ExportOptionsPlist) throws {
		try write(content)
	}
}

extension ExportOptionsWriter: DisposableFeature {
	static var placeholder: ExportOptionsWriter {
		ExportOptionsWriter(
			write: unimplemented1()
		)
	}
}

extension ExportOptionsWriter {
	static func system() -> FeatureLoader {
		.disposable { exportPlistPath, features -> ExportOptionsWriter in
			ExportOptionsWriter(
				write: { content in
					Logger.info("Saving export plist.")
					let exportOptionPlistUrl: URL = URL(
						fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true
					)
					.appendingPathComponent(exportPlistPath.rawValue)
					try FileManager.default.createDirIfNotExists(exportOptionPlistUrl.deletingLastPathComponent().path)
					let exportOptionsPlistContentData: Data = try PropertyListSerialization.data(
						fromPropertyList: content.convertKeysToRawTypes(), format: .xml, options: 0)
					try exportOptionsPlistContentData.write(to: exportOptionPlistUrl)
					Logger.successInfo("Export plist saved at path: \(exportPlistPath).")
				}
			)
		}
	}
}
