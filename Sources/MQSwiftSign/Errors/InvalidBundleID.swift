import Foundation
import MQ

internal struct InvalidBundleID: TheError {
	internal var displayableMessage: DisplayableString
	internal var context: MQ.SourceCodeContext
	internal var hintMessage: String

	internal static func error(
		message: StaticString = "InvalidBundleID",
		hintMessage: String = "Check if bundleID contains only valid characters",
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
			hintMessage: hintMessage
		)
	}
}
