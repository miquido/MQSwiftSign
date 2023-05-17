import Foundation

extension URL: Validator {

	typealias ValidatedType = String

	var value: String {
		self.path
	}

	init(
		path: String,
		isDirectory: Bool = false
	) throws {
		let url = URL(fileURLWithPath: path, isDirectory: isDirectory)
		if !url.isValid() {
			throw InvalidURL.error()
		}
		self = url
	}

	func isValid() -> Bool {
		if FileManager.default.fileExists(atPath: value) {
			return true
		}
		return false
	}

}
