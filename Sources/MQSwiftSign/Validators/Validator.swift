import Foundation

protocol Validator {
	associatedtype ValidatedType

	var value: ValidatedType { get }
	func isValid() -> Bool
}
