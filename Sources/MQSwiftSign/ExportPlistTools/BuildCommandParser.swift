import Foundation
import RegexBuilder

internal typealias BuildCommandRegex = Regex<(Substring, BuildCommandOption, String)>

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
	var commandOptionsSearchRegexp: BuildCommandRegex { get }
	var commandOptions: BuildCommandOptions { get }

	init(shellScript: String)
}

internal struct FlutterBuildCommand: BuildCommand {
	internal var exportPlistPath: String
	internal var commandOptions: BuildCommandOptions
	internal var commandOptionsSearchRegexp: BuildCommandRegex = Regex {
		TryCapture {
			ChoiceOf {
				"--export-options-plist"
			}
		} transform: {
			BuildCommandOption(rawValue: String($0))
		}
		"="
		Capture {
			OneOrMore(CharacterClass(.word, .anyOf("./\\")))
			ZeroOrMore {
				Optionally(CharacterClass(.whitespace, .anyOf("-./")))
				OneOrMore(.word)
			}
		} transform: {
			String($0)
		}
	}

	init(shellScript: String) {
		var options = shellScript.extractExportOptions(using: commandOptionsSearchRegexp)
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
	internal var commandOptionsSearchRegexp: BuildCommandRegex = Regex {
		TryCapture {
			ChoiceOf {
				"-target"
				"-configuration"
				"-exportOptionsPlist"
				"-scheme"
				"-workspace"
				"-project"
				"-sdk"
			}
		} transform: {
			BuildCommandOption(rawValue: String($0))
		}
		OneOrMore(.whitespace)
		Capture {
			OneOrMore(CharacterClass(.word, .anyOf("./\\")))
			ZeroOrMore {
				Optionally(CharacterClass(.whitespace, .anyOf("-./")))
				OneOrMore(.word)
			}
		} transform: {
			String($0)
		}
	}

	internal init(shellScript: String) {
		self.commandOptions = shellScript.extractExportOptions(using: commandOptionsSearchRegexp)
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
	func extractExportOptions(using regexp: BuildCommandRegex) -> BuildCommandOptions {
		var options = BuildCommandOptions()
		self.matches(of: regexp)
			.forEach { match in
				let (_, option, value) = match.output
				options[option] = String(value).trimmingCharacters(in: CharacterSet(charactersIn: " "))
					.replacingOccurrences(of: "\\", with: "")
			}
		return options
	}
}
