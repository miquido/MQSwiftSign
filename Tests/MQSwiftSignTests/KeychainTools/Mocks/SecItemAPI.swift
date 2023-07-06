import Foundation

@testable import MQSwiftSign

extension SecItemAPI {
	static var test: SecItemAPI {
		SecItemAPI(
			import: { _, _, _ in errSecSuccess },
			createParameters: { _, _ in SecItemImportExportKeyParameters() }
		)
	}
}
