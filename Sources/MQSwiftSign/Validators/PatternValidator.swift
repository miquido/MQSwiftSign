import Foundation

protocol PatternValidator: Validator where ValidatedType == String {
	var pattern: String { get }
}

extension PatternValidator {
	func isValid() -> Bool {
		if let _ = try? NSRegularExpression(pattern: pattern)
			.firstMatch(
				in: value, range: NSRange(value.startIndex..<value.endIndex, in: value))
		{
			return true
		}
		return false
	}
}
