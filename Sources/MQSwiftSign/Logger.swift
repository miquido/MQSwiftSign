import Foundation

internal struct Logger {
	private(set) internal static var emojiModeEnabled: Bool = true
	private(set) internal static var colorModeEnabled: Bool = true

	private static var date: String {
		Date().formatted(date: .omitted, time: .standard)
	}

	internal static func configure(showEmojis: Bool, colorizeMessages: Bool) {
		emojiModeEnabled = showEmojis
		colorModeEnabled = colorizeMessages
	}

	internal static func successInfo(_ message: String) {
		guard let data = getMessage(content: message, type: .successInfo) else { return }
		FileHandle.standardOutput.write(data)
	}

	internal static func info(_ message: String) {
		guard let data = getMessage(content: message, type: .info) else { return }
		FileHandle.standardOutput.write(data)
	}

	internal static func warning(_ message: String) {
		guard let data = getMessage(content: message, type: .warning) else { return }
		FileHandle.standardOutput.write(data)
	}

	internal static func error(_ message: String) {
		guard let data = getMessage(content: message, type: .error) else { return }
		FileHandle.standardError.write(data)
	}

	private static func getMessage(content: String, type: LogType) -> Data? {
		let headerWithDate: String = colorMessageIfRequired("\(date) \(type.header)", color: type.color, bold: true)
		let emoji = emojiModeEnabled ? type.emoji : ""
		let message =
			"\(headerWithDate) \(emoji) : \(colorMessageIfRequired(content, color: type.color, bold: false))\n"
		return message.data(using: .utf8)
	}

	private static func colorMessageIfRequired(_ message: String, color: String.ANSIColor, bold: Bool = false) -> String
	{
		guard colorModeEnabled else { return message }
		return message.colorize(with: color, bold: bold)
	}

}

extension Logger {
	private enum LogType {
		case successInfo
		case info
		case warning
		case error

		var header: String {
			switch self {
			case .info, .successInfo:
				return "INFO"
			case .warning:
				return "WARNING"
			case .error:
				return "ERROR"
			}
		}

		var emoji: String {
			switch self {
			case .info, .successInfo:
				return "ℹ️"
			case .warning:
				return "⚠️"
			case .error:
				return "🚨"
			}
		}

		var color: String.ANSIColor {
			switch self {
			case .successInfo:
				return .green
			case .info:
				return .cyan
			case .warning:
				return .yellow
			case .error:
				return .red
			}
		}
	}
}

private extension String {
	enum ANSIColor: UInt {
		case red = 31
		case green = 32
		case yellow = 33
		case cyan = 36
		case `default` = 0

		fileprivate func code(bold: Bool) -> String {
			"\u{001B}[\(bold ? 1 : 0);\(rawValue)m"
		}
	}

	func colorize(with color: ANSIColor = .default, bold: Bool) -> String {
		color.code(bold: bold) + self + ANSIColor.default.code(bold: false)
	}
}
