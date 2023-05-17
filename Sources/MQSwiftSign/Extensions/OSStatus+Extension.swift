import Foundation
import MQ

extension OSStatus {
	var errorMessage: String {
		SecCopyErrorMessageString(self, nil).map { String($0) } ?? ""
	}

	func onFailThrowing(_ error: TheError) throws {
		guard self == errSecSuccess else {
			throw error
		}
	}
}
