import Foundation

internal extension FileManager {

	func createDirIfNotExists(_ path: String) throws {
		if !fileExists(atPath: path) {
			try createDirectory(atPath: path, withIntermediateDirectories: true)
		}
	}

}
