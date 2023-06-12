import Foundation
import MQDo
import MQTagged

struct Preferences {
	var get: (PreferenceKey) -> String?
	var set: (PreferenceKey, String) -> Void
	var remove: (PreferenceKey) -> Void
}

extension Preferences {
	typealias PreferenceKey = Tagged<String, Preferences>

	func set(_ value: String, forKey key: PreferenceKey) {
		set(key, value)
	}

}

extension Preferences.PreferenceKey {
	static var keychainName: Self = "MQSWIFTSIGN_KEYCHAIN_NAME"
}

extension Preferences: DisposableFeature {
	static var placeholder: Preferences {
		Preferences(
			get: unimplemented1(),
			set: unimplemented2(),
			remove: unimplemented1()
		)
	}
}

extension Preferences {
	static func defaults() -> FeatureLoader {
		.disposable { features -> Preferences in
			Preferences(
				get: { key in
					UserDefaults.standard.string(forKey: key.rawValue)
				},
				set: { key, value in
					UserDefaults.standard.set(value, forKey: key.rawValue)
				},
				remove: { key in
					UserDefaults.standard.removeObject(forKey: key.rawValue)
				}
			)
		}
	}
}
