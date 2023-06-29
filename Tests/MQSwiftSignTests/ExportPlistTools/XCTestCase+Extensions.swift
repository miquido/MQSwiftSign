import XCTest

extension XCTestCase {
	func assertThrowsError<E: Error, R>(
		_ expression: @autoclosure () throws -> R,
		_ expectedError: E,
		file: StaticString = #file,
		line: UInt = #line
	) {
		do {
			try expression()
			XCTFail("No error was thrown. Expected: \(expectedError)", file: file, line: line)
		} catch is E {
			// Expected error is thrown
		} catch {
			XCTFail("Unexpected error: \(error)", file: file, line: line)
		}
	}
}
