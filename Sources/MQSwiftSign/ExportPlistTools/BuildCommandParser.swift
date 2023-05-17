import Foundation

internal struct BuildCommandParser {
	static func from(shellScript: String) -> BuildCommand {
		if shellScript.starts(with: "flutter") || shellScript.starts(with: "fvm") {
			return FlutterBuildCommand(shellScript: shellScript)
		}
		return IosBuildCommand(shellScript: shellScript)
	}
}

internal protocol BuildCommand {
	var exportPlistPath: String { get }
	var commandOptionsSearchRegexp: String { get }
	var commandOptionsSeparator: Character { get }
	var commandOptions: BuildCommandOptions { get }

	init(shellScript: String)
}

internal struct FlutterBuildCommand: BuildCommand {
	internal var exportPlistPath: String
	internal var commandOptions: BuildCommandOptions

	internal var commandOptionsSearchRegexp: String = #"--[^&|\s]*"#
	internal var commandOptionsSeparator: Character = "="

	init(shellScript: String) {
		var options = shellScript.extractExportOptions(
			using: commandOptionsSearchRegexp, and: commandOptionsSeparator)
		// flutter build command does not provide project nor scheme nor target, but always uses "Runner" instead - so we can hardcode it
		options[.projectPath] = "./ios/Runner.xcodeproj"
		options[.schemeName] = "Runner"
		options[.targetName] = "Runner"
		self.commandOptions = options
		guard let exportPlistPath = options[.exportPlistPathFlutter] else {
			let defaultPath = "./ios/ExportOptionsPlists/exportOption.plist"
			Logger.info(
				"Output path for ExportOptions.plist (\(BuildCommandOption.exportPlistPathFlutter.rawValue)) not provided."
			)
			Logger.info("Using the default path (\(defaultPath)) instead.")
			self.exportPlistPath = defaultPath
			return
		}
		self.exportPlistPath = exportPlistPath
	}
}

internal struct IosBuildCommand: BuildCommand {
	internal var exportPlistPath: String
	internal var commandOptions: BuildCommandOptions

	internal var commandOptionsSearchRegexp: String = #"-[^-&\s|]*\s(([^-&|]*[\s][^&\s-|]+)|([^-&][^\s]+))?"#
	internal var commandOptionsSeparator: Character = " "

	internal init(shellScript: String) {
		self.commandOptions = shellScript.extractExportOptions(
			using: commandOptionsSearchRegexp, and: commandOptionsSeparator)
		guard let exportPlistPath = commandOptions[.exportPlistPath] else {
			let defaultPath = "./ExportOptionsPlists/exportOption.plist"
			Logger.info(
				"Output path for ExportOptions.plist (\(BuildCommandOption.exportPlistPath.rawValue)) not provided."
			)
			Logger.info("Using the default path (\(defaultPath)) instead.")
			self.exportPlistPath = defaultPath
			return
		}
		self.exportPlistPath = exportPlistPath
	}
}

private extension String {
	func extractExportOptions(using regexp: String, and separator: Character) -> BuildCommandOptions {
		let parameters = self.getSubstrings(matching: regexp)
		return parameters.reduce(into: BuildCommandOptions()) { partialResult, parameter in
			let substrings = parameter.split(separator: separator).map { String($0) }
			guard let option = BuildCommandOption(rawValue: substrings[0]) else { return }
			partialResult[option] = substrings[1..<substrings.count].joined(separator: " ")
				.replacingOccurrences(of: "\\ ", with: " ")
		}
	}

	func getSubstrings(matching pattern: String) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: pattern)
			let textRange = self.startIndex..<self.endIndex
			let range = NSRange(textRange, in: self)
			let matchingResult = regex.matches(in: self, range: range)
			let matchedStrings: [String] = matchingResult.compactMap {
				guard let currentRange = Range($0.range, in: self) else { return nil }
				return String(self[currentRange])
			}
			return matchedStrings
		} catch {
			return []
		}
	}
}
