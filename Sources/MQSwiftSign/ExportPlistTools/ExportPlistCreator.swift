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
	private let optionsWriter: ExportOptionsWriter
	private let optionsExtractor: ExportOptionsExtractor

	init(with context: PlistCreator.Context, using features: Features) throws {
		self.buildCommand = BuildCommandParser.from(shellScript: context.shellScript)
		self.distributionMethod = context.distributionMethod
		self.optionsWriter = try features.instance(context: ExportPath(rawValue: buildCommand.exportPlistPath))
		self.optionsExtractor = try features.instance(context: buildCommand.commandOptions)
	}

	func createExportPlist() throws {
		var exportOptions = try optionsExtractor.extract()
		exportOptions.setDistributionMethod(distributionMethod.rawValue)
		try optionsWriter.write(exportOptions)
	}

	var instance: PlistCreator {
		.init(create: createExportPlist)
	}
}
