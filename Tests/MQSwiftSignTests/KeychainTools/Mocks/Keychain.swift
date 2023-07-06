import Foundation

@testable import MQSwiftSign

extension Keychain {
	static func test() -> Keychain {
		Keychain(
			setup: noop,
			import: noop,
			setACLs: noop
		)
	}
}
