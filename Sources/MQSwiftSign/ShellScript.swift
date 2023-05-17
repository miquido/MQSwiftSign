import Foundation

struct ShellScript {
	private var script: String

	init(_ script: String) {
		self.script = script
	}

	func execute() throws {
        try execute(script)
	}
}

private extension ShellScript {
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
