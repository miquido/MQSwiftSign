import Foundation
import RegexBuilder

protocol PatternValidator: Validator where ValidatedType == String {
	var pattern: Regex<Substring> { get }
}

extension PatternValidator {
	func isValid() -> Bool {
		return value.firstMatch(of: pattern) != nil
	}
}
