import ArgumentParser
import Foundation

extension MQSwiftSign {
	struct Run: ParsableCommand {

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
			defer { try? Cleanup().run() }
			var prepareCommand = Prepare(prepareOptions: prepareOptions)
			try prepareCommand.run()

			if let distributionMethodString = self.distributionMethod {
				guard let distributionMethod = DistributionMethod(rawValue: distributionMethodString)
				else {
					throw ExportPlistCreationFailed.error(
						message:
							"Invalid distribution method. Plist cannot be created. If you want to create plist manually, consider omitting this parameter."
					)
				}
				let exportPlistManager = ExportPlistCreator(
					distributionMethod: distributionMethod,
                    shellScript: shellScript)
				Logger.info(
					"Detected distribution method \(distributionMethod). Creating export plist...")
				try exportPlistManager.createExportPlist()
			} else {
				Logger.error(
					"No distribution method found. Plist won't be created. If you want to build the app, ensure that plist is provided."
				)
			}
			let scriptToExecute = ShellScript(shellScript)
			try scriptToExecute.execute()
		}
	}
}
