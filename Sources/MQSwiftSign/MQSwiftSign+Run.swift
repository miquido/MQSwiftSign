import ArgumentParser
import MQDo

import func Foundation.exit

extension MQSwiftSign {
	struct Run: ParsableCommand, MQSwiftSignCommand {

		static var configuration: CommandConfiguration {
			CommandConfiguration(commandName: "run")
		}

		@OptionGroup private var prepareOptions: PrepareOptions

		@Option(
			name: .long,
			help:
				"Shell script to be executed after the certificate is imported into keychain. Normally it should contain build/archive/export commands. After execution, script will automatically clean up itself"
		)
		private var shellScript: String

		@Option(
			name: .long,
			help:
				"The app distribution method. If this parameter is given and the '--shell-script' argument contains correct build commands then an export plist file will be created at location specified in `xcodebuild` commands. If this parameter is omitted then no export plist file will be created."
		)
		private var distributionMethod: String?

		mutating func run() throws {
			try run(features)
		}

		mutating func run(_ features: Features) throws {
			defer {
				let factory: MQSwiftSignCommandFactory? = try? features.instance()
				var command = factory?.cleanup()
				try? command?.run(features)
			}
			cleanupOnTermination()
			let factory: MQSwiftSignCommandFactory = try features.instance()
			var prepareCommand = factory.prepare(prepareOptions)
			try prepareCommand.run(features)

			if let distributionMethodString = self.distributionMethod {
				guard let distributionMethod = DistributionMethod(rawValue: distributionMethodString)
				else {
					throw ExportPlistCreationFailed.error(
						message:
							"Invalid distribution method. Plist cannot be created. If you want to create plist manually, consider omitting this parameter."
					)
				}
				let context = PlistCreator.Context(distributionMethod: distributionMethod, shellScript: shellScript)
				let plistCreator: PlistCreator = try features.instance(context: context)

				Logger.info(
					"Detected distribution method \(distributionMethod). Creating export plist...")
				try plistCreator.create()
			} else {
				Logger.warning(
					"No distribution method found. Plist won't be created. If you want to build the app, ensure that plist is provided."
				)
			}
			let executor: ShellScriptExecutor = try features.instance()
			try executor.execute(shellScript)
		}

		func cleanupOnTermination() {
			TerminationSignal.allCases.handle { code in
				Logger.info("Received termination signal with code: \(code).")
				do {
					try Cleanup().run()
				} catch {
					Logger.error("Cleanup failed with error: \(error)")
				}
				Foundation.exit(code)
			}
		}
	}
}
