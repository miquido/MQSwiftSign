import ArgumentParser
import Foundation
import MQ

@main
struct MQSwiftSign: ParsableCommand {
	static var configuration = CommandConfiguration(
		subcommands: [Prepare.self, Run.self, Cleanup.self],
		defaultSubcommand: Run.self)
}
