import XCTest

struct File {
	let fileUrl: URL
	let content: String

	init(content: String) throws {
		self.content = content
		let temporaryDirURL = URL(fileURLWithPath: NSTemporaryDirectory())
		self.fileUrl = temporaryDirURL.appendingPathComponent("mockFile.mobileprovision")
		try content.write(to: fileUrl, atomically: true, encoding: .utf8)
	}
}
