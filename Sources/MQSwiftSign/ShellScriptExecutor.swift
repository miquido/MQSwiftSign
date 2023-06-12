import Foundation
import MQDo

struct ShellScriptExecutor {
	var execute: (String) throws -> Void
}

extension ShellScriptExecutor: DisposableFeature {
	static var placeholder: ShellScriptExecutor {
		ShellScriptExecutor(
			execute: unimplemented1()
		)
	}
}

struct SystemShellScriptExecutor: ImplementationOfDisposableFeature {

	init(with context: Void, using features: Features) throws {}

	var instance: ShellScriptExecutor {
		.init(
			execute: execute
		)
	}

	func execute(_ script: String) throws {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/bin/sh")
		process.arguments = ["-o", "pipefail", "-c", script]

		Logger.info("Shell script `\(script)` is being executed now.")
		try process.run()
		process.waitUntilExit()
		Logger.info("Shell script `\(script)` finished executing with status code: \(process.terminationStatus)")

		if process.terminationStatus != 0 {
			throw ShellScriptFailed.error(message: "Failed executing shell script.")
		}
	}
}
