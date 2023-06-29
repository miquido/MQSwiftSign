import XCTest

@testable import MQSwiftSign

final class FlutterBuildCommandRegexTests: XCTestCase {

	// MARK: For all Flutter cases:
	// Flutter build command does not provide project nor scheme nor target, but always uses "Runner" instead - so we could hardcode it. In result command options dict always contains these three parameters
	var defaultBuildCommandOptions: BuildCommandOptions {
		[
			.projectPath: "./ios/Runner.xcodeproj",
			.schemeName: "Runner",
			.targetName: "Runner",
		]
	}

	func test_givenOneOption_regexFindsMatch() throws {
		let givenShellScript = "fvm flutter build ipa --export-options-plist=./ExportOptionsPlist"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.exportPlistPathFlutter: "./ExportOptionsPlist"
		]
		.merging(defaultBuildCommandOptions) { current, _ in current }
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenExtraOptions_regexFindsMatch() throws {
		let givenShellScript =
			"fvm flutter build ipa --export-options-plist=./ExportOptionsPlist --project My Project -scheme My Project Dev"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.exportPlistPathFlutter: "./ExportOptionsPlist"
		]
		.merging(defaultBuildCommandOptions) { current, _ in current }
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenOptionsOnlyBeyondCommandOptions_regexFindsNoMatch() throws {
		let givenShellScript = "fvm flutter build ipa --project My Project -scheme My Project Dev"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = defaultBuildCommandOptions
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenOneOptionWithIncorrectSeparator_regexFindsNoMatch() throws {
		let givenShellScript = "fvm flutter build ipa --export-options-plist ./ExportOptionsPlist"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = defaultBuildCommandOptions
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenOneOptionWithOnlyOneDashSeparator_regexFindsNoMatch() throws {
		let givenShellScript = "fvm flutter build ipa -export-options-plist=./ExportOptionsPlist"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = defaultBuildCommandOptions
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenNoOptions_regexFindsNoMatch() throws {
		let givenShellScript = "fvm flutter build ipa"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = defaultBuildCommandOptions
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenEmptyShellScript_regexFindsNoMatch() throws {
		let givenShellScript = ""
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = defaultBuildCommandOptions
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenDashInTheMiddleOfOption_regexFindsMatch() throws {
		let givenShellScript =
			"fvm flutter build ipa --export-options-plist=./ExportOptionsPlist/export-options.plist"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.exportPlistPathFlutter: "./ExportOptionsPlist/export-options.plist"
		]
		.merging(defaultBuildCommandOptions) { current, _ in current }
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenDashInTheMiddleOfOptionMoreThanOnce_regexFindsMatch() throws {
		let givenShellScript =
			"fvm flutter build ipa --export-options-plist=./Export-Options-Plist/export-options.plist"
		let commandParser: BuildCommand = FlutterBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.exportPlistPathFlutter: "./Export-Options-Plist/export-options.plist"
		]
		.merging(defaultBuildCommandOptions) { current, _ in current }
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

}
