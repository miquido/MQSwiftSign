import ArgumentParser
import Foundation
import MQ
import MQDo

@main
struct MQSwiftSign: ParsableCommand {
	static var configuration = CommandConfiguration(
		subcommands: [Prepare.self, Run.self, Cleanup.self],
		defaultSubcommand: Run.self)

}

let features: Features = FeaturesRoot { registry in
	registry.use(SystemKeychain.self)
	registry.use(Preferences.defaults())
	registry.use(SystemKeychainItemAccessManager.self)
	registry.use(KeychainSearcher.system())
	registry.use(ProvisioningInstaller.system())
	registry.use(ExportPlistCreator.self)
	registry.use(MQSwiftSignCommandFactory.default())
	registry.use(SystemShellScriptExecutor.self)
	registry.useCoreFoundationAPIs()
}
