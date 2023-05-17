import Foundation
import MQ

internal struct KeychainItemSearchFailed: TheError {
	internal var displayableMessage: DisplayableString
	internal var context: MQ.SourceCodeContext

	internal static func error(
		message: StaticString = "KeychainItemSearchFailed",
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
			)
		)
	}
}
