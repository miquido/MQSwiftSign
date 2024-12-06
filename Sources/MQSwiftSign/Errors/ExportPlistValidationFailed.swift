import Foundation
import MQ

internal struct ExportPlistValidationFailed: TheError {
    internal var displayableMessage: DisplayableString
    internal var context: MQ.SourceCodeContext
    internal var hintMessage: String

    internal static func error(
        message: StaticString = "ExportPlistValidationFailed",
        hintMessage: String = "",
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
