import Foundation

extension Array where Element == String {

	func createAccessRefs() -> [SecTrustedApplication?] {
		self.map {
			var accessItem: SecTrustedApplication?
			SecTrustedApplicationCreateFromPath($0, &accessItem)
			return accessItem
		}
	}

}
