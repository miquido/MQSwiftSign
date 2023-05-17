import Foundation

struct Logger {

	private static var date: String {
		Date().formatted(date: .omitted, time: .standard)
	}

	static func info(_ message: String) {
		let message = "[\(date)]: INFO : \(message)\n"
		guard let data = message.data(using: .utf8) else { return }
		FileHandle.standardOutput.write(data)
	}

	static func error(_ errorMessage: String) {
		let message = "[\(date)]: ERROR 🚨 : \(errorMessage)\n"
		guard let data = message.data(using: .utf8) else { return }
		FileHandle.standardOutput.write(data)
	}

}
