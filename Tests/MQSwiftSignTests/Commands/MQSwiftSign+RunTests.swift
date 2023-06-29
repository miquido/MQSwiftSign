import Foundation
@testable import MQSwiftSign

final class MQSwiftSign_Run_Tests: FeatureTests {
	func testShouldFailIfPrepareFails() async {
		await test(
			patches: { patches in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: alwaysThrowing(InvalidCertificate.error()))
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: noop) }
				)
			},
			throws: InvalidCertificate.self,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\""])
				try sut.run(features)
			}
		)
	}

	func testShouldFailIfDistributionMethodIsInvalid() async {
		await test(
			patches: { patches in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: noop)
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: noop) }
				)
			},
			throws: ExportPlistCreationFailed.self,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\"", "--distribution-method", "invalid"])
				try sut.run(features)
			}
		)
	}

	func testShouldCreateExportOptionsPlistIfDistributionMethodIsProvided() async throws {
		await test(
			patches: { patches, executed in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: noop)
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: noop) }
				)
				patches(
					patch: \ShellScriptExecutor.execute,
					with: noop
				)
				patches(
					patch: \PlistCreator.create,
					with: {
						executed()
					}
				)
			},
			executedPrepared: 1,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\"", "--distribution-method", "app-store"])
				try sut.run(features)
			}
		)
	}

	func testShouldNotCreateExportOptionsPlistIfDistributionMethodIsNotProvided() async throws {
		await test(
			patches: { patches, executed in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: noop)
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: noop) }
				)
				patches(
					patch: \ShellScriptExecutor.execute,
					with: noop
				)
				patches(
					patch: \PlistCreator.create,
					with: {
						executed()
					}
				)
			},
			executedPrepared: 0,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\""])
				try sut.run(features)
			}
		)
	}

	func testShouldFailIfPlistCreationFail() async {
		await test(
			patches: { patches in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: noop)
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: noop) }
				)
				patches(
					patch: \PlistCreator.create,
					with: alwaysThrowing(NoSuchFile.error())
				)
			},
			throws: NoSuchFile.self,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\"", "--distribution-method", "app-store"])
				try sut.run(features)
			}
		)
	}

	func testShouldFailIfShellScriptFails() async {
		await test(
			patches: { patches in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: noop)
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: noop) }
				)
				patches(
					patch: \ShellScriptExecutor.execute,
					with: alwaysThrowing(ShellScriptFailed.error())
				)
			},
			throws: ShellScriptFailed.self,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\""])
				try sut.run(features)
			}
		)
	}

	func testShouldPerformCleanupAfterCommandExecutes() async {
		await test(
			patches: { patches, executed in
				patches(
					patch: \MQSwiftSignCommandFactory.prepare,
					with: { options in
						CommandMock(run: noop)
					}
				)
				patches(
					patch: \MQSwiftSignCommandFactory.cleanup,
					with: { CommandMock(run: { _ in executed() }) }
				)
				patches(
					patch: \ShellScriptExecutor.execute,
					with: noop
				)
			},
			executedPrepared: 1,
			execute: { features in
				var sut = try MQSwiftSign.Run.parse([self.mockedCertificate, "--shell-script", "echo \"OK\""])
				try sut.run(features)
			}
		)
	}
}

struct CommandMock: MQSwiftSignCommand {
	var run: (Features) throws -> Void
	func run(_ features: Features) throws {
		try run(features)
	}
}


private extension MQSwiftSign_Run_Tests {
	var mockedCertificate: String {
		"randomText".data(using: .unicode)!.base64EncodedString()
	}
}
