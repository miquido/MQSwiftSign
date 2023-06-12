import MQDo

extension FeaturesRegistry {
	mutating func useCoreFoundationAPIs() {
		use(SecKeychainAPI.system())
		use(SecItemAPI.system())
		use(SecAccessAPI.system())
		use(SecACLAPI.system())
		use(SecKeychainItemAPI.system())
	}
}
