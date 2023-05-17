import Foundation

internal typealias BuildCommandOptions = Dictionary<BuildCommandOption, String>

internal enum BuildCommandOption: String {
	case targetName = "-target"
	case configurationName = "-configuration"
	case exportPlistPath = "-exportOptionsPlist"
	case schemeName = "-scheme"
	case workspacePath = "-workspace"
	case projectPath = "-project"
	case sdk = "-sdk"

	case exportPlistPathFlutter = "--export-options-plist"
}
