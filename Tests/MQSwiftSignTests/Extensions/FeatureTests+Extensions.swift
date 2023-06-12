import Foundation
import MQAssert

extension FeatureTests {
	func test<Returned, ExpectedError: Error>(
		throws expected: ExpectedError.Type,
		execute: @escaping (DummyFeatures) async throws -> Returned,
		file: StaticString = #filePath,
		line: UInt = #line
	) async {
		await test(
			patches: { _ in },
			throws: expected,
			execute: execute,
			file: file,
			line: line
		)
	}

	func test<ExpectedError: Error>(
		throws expected: ExpectedError.Type,
		execute: @escaping () async throws -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) async {
		await test(
			patches: { _ in },
			throws: expected,
			execute: { _ in try await execute() },
			file: file,
			line: line
		)
	}
}
