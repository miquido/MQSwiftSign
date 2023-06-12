import Foundation
@testable import MQSwiftSign

extension SecKeychainAPI {
	static var test: SecKeychainAPI {
		SecKeychainAPI(
			get: always(nil),
			create: always(.empty),
			addToSearchList: noop,
			setDefaultSettings: noop,
			unlock: noop,
			delete: noop,
			forceDelete: noop
		)
	}
}
