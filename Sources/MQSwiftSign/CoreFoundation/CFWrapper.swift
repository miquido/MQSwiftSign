import Foundation

/// Wrapper for core foundation types to make unit tests easier.
protocol CFWrappable: Hashable {}

struct CFWrapper<T: CFWrappable> {
	let value: T?
	private var hashValue: Int

	init(_ value: T?) {
		self.value = value
		self.hashValue = value?.hashValue ?? 0
	}

	static var empty: CFWrapper<T> {
		CFWrapper(nil)
	}
}

extension CFWrapper: Equatable {
	static func == (lhs: CFWrapper<T>, rhs: CFWrapper<T>) -> Bool {
		lhs.hashValue == rhs.hashValue
	}
}

extension SecKeychain: CFWrappable {
	var wrapped: CFWrapper<SecKeychain> {
		CFWrapper(self)
	}
}

extension SecKeychainItem: CFWrappable {
	var wrapped: CFWrapper<SecKeychainItem> {
		CFWrapper(self)
	}
}

extension SecAccess: CFWrappable {
	var wrapped: CFWrapper<SecAccess> {
		CFWrapper(self)
	}
}

extension SecTrustedApplication: CFWrappable {
	var wrapped: CFWrapper<SecTrustedApplication> {
		CFWrapper(self)
	}
}

extension SecACL: CFWrappable {
	var wrapped: CFWrapper<SecACL> {
		CFWrapper(self)
	}
}
