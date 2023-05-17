import Foundation
import MQ

internal struct KeychainDeletionFailed: TheError {
	internal var context: MQ.SourceCodeContext

	internal static func error(
		message: StaticString = "Keychain deletion failed",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
