import Foundation
import RegexBuilder

extension String {

	func getCStringWithLength() throws -> ([CChar], Int) {
		guard let password = self.cString(using: .utf8) else {
			throw DecodingFailed.error(message: "Decoding password using utf-8 failed")
		}
		let passwordLength = strlen(password)
		return (password, passwordLength)
	}

}
