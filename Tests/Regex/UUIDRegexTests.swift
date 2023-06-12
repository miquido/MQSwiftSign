import XCTest

@testable import MQSwiftSign

final class UUIDRegexTests: XCTestCase {

	private let searcher: FileSearcher = UUIDSearcher()

	func test_givenValidUUIDString_regexFindsMatch() throws {
		let givenUUID: String = "123e4567-e89b-12d3-a456-426655440000"
		let fileContent: String = """
			    <key>UUID</key>
			    <string>\(givenUUID)</string>
			"""
		let file: URL = try File(content: fileContent).fileUrl
		let uuid: String = try searcher.search(in: file)
		XCTAssertEqual(uuid, givenUUID)
	}

	func test_givenInvalidUUIDString_wrongLength_regexDoesNotFindMatch() throws {
		let givenUUID: String = "123e4567-e89b-12d3-a456"
		let fileContent: String = """
			    <key>UUID</key>
			    <string>\(givenUUID)</string>
			"""
		let file: URL = try File(content: fileContent).fileUrl
		XCTAssertThrowsError(try searcher.search(in: file))
	}

	func test_givenInvalidCharactersUUIDString_regexDoesNotFindMatch() throws {
		let givenUUID: String = "?23e4!67-e89b-12d3-a456-4266554?0000"
		let fileContent: String = """
			    <key>UUID</key>
			    <string>\(givenUUID)</string>
			"""
		let file: URL = try File(content: fileContent).fileUrl
		XCTAssertThrowsError(try searcher.search(in: file))
	}

	func test_givenMissingUUIDStringKey_regexDoesNotFindMatch() throws {
		let givenUUID: String = "123e4567-e89b-12d3-a456-426655440000"
		let fileContent: String = """
			    <key>SomeKey</key>
			    <string>\(givenUUID)</string>
			"""

		let file: URL = try File(content: fileContent).fileUrl
		XCTAssertThrowsError(try searcher.search(in: file))
	}

}
