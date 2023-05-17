import Foundation
import MQ

internal struct NoSuchFile: TheError {

	internal enum Reason {
		case wrongSchemeName
		case wrongProjectPath
		case wrongWorkspacePath
		case wrongEntitlementsPath
		case wrongProvisioningPath

		var description: String {
			switch self {
			case .wrongSchemeName:
				return "Wrong scheme name provided"
			case .wrongProjectPath:
				return "Wrong project path provided"
			case .wrongWorkspacePath:
				return "Wrong workspace path provided"
			case .wrongEntitlementsPath:
				return "Wrong entitlements path found in project config"
			case .wrongProvisioningPath:
				return "Wrong provisioning path provided"
			}
		}
	}

	internal var displayableMessage: DisplayableString
	internal var context: MQ.SourceCodeContext
	internal var possibleReasons: [String]

	internal static func error(
		message: StaticString = "NoSuchFile",
		possibleReasons: [Reason] = [],
		displayableMessage: DisplayableString = TheErrorDisplayableMessages.message(for: Self.self),
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: displayableMessage,
			context: .context(
				message: message,
				file: file,
				line: line
			),
			possibleReasons: possibleReasons.map { $0.description }
		)
	}
}
