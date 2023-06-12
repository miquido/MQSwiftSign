import Foundation
import MQDo


struct PlistCreator {
	var create: () throws -> Void

	struct Context {
		var distributionMethod: DistributionMethod
		var shellScript: String
	}
}

extension PlistCreator: DisposableFeature {
	static var placeholder: PlistCreator {
		PlistCreator(
			create: unimplemented0()
		)
	}
}

internal struct ExportOptionsPlist {
	private(set) var properties: Dictionary<ExportPlistOption, Any>

	init(properties: Dictionary<ExportPlistOption, Any>) {
		self.properties = properties
	}

	internal mutating func setDistributionMethod(_ method: String) {
		properties[.method] = method
	}

	internal func convertKeysToRawTypes() -> Dictionary<String, Any> {
		return Dictionary(uniqueKeysWithValues: properties.map { key, value in (key.rawValue, value) })
	}
}

internal enum ExportPlistOption: String {
	case teamID
	case signingStyle
	case signingCertificate
	case uploadBitcode
	case compileBitcode
	case uploadSymbols
	case provisioningProfiles
	case iCloudContainerEnvironment
	case method
}

struct ExportPlistCreator: ImplementationOfDisposableFeature {
	private let buildCommand: BuildCommand
	private let distributionMethod: DistributionMethod

	init(with context: PlistCreator.Context, using _: Features) throws {
		self.buildCommand = BuildCommandParser.from(shellScript: context.shellScript)
		self.distributionMethod = context.distributionMethod
	}

	func createExportPlist() throws {
		let projectParser: ProjectParser = ProjectParser(
			options: buildCommand.commandOptions,
			distributionMethod: distributionMethod)
		let parsedProject: ProjectFile = try projectParser.parseProject()
		let tree: TargetDependencyTree = try parsedProject.prepareTargetDependencyTree()
		var exportOptions: ExportOptionsPlist = try tree.exportOptionsPlistContent()
		exportOptions.setDistributionMethod(distributionMethod.rawValue)
		try saveExportPlist(exportOptions)
	}

	var instance: PlistCreator {
		.init(create: createExportPlist)
	}
}

private extension ExportPlistCreator {
	private func saveExportPlist(_ content: ExportOptionsPlist) throws {
		Logger.info("Saving export plist.")
		let exportOptionPlistUrl: URL = URL(
			fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true
		)
		.appendingPathComponent(buildCommand.exportPlistPath)
		try FileManager.default.createDirIfNotExists(exportOptionPlistUrl.deletingLastPathComponent().path)
		let exportOptionsPlistContentData: Data = try PropertyListSerialization.data(
			fromPropertyList: content.convertKeysToRawTypes(), format: .xml, options: 0)
		try exportOptionsPlistContentData.write(to: exportOptionPlistUrl)
		Logger.successInfo("Export plist saved at path: \(buildCommand.exportPlistPath).")
	}
}
