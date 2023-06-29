import XCTest

@testable import MQSwiftSign

final class IOSBuildCommandRegexTests: XCTestCase {

	func test_givenAllCommandOptions_regexFindsSevenMatch() throws {
		let givenShellScript =
			"xcodebuild archive -project MyProject.xcodeproj -workspace MyProject.xcworkspace -target MyProject -scheme MyProject\\ Dev -configuration Dev -sdk iphoneos -exportOptionsPlist ./ExportOptionsPlist"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.projectPath: "MyProject.xcodeproj",
			.workspacePath: "MyProject.xcworkspace",
			.targetName: "MyProject",
			.schemeName: "MyProject Dev",
			.configurationName: "Dev",
			.sdk: "iphoneos",
			.exportPlistPath: "./ExportOptionsPlist",
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenExtraOptionsNotBelongToCommandOptions_regexFindsFiveMatch() throws {
		let givenShellScript =
			"xcodebuild archive -project MyProject.xcodeproj -target MyProject -configuration Dev -sdk iphoneos -archivePath ./MyProject.xcarchive | tee -a archive.txt -exportOptionsPlist ./ExportOptionsPlist"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.projectPath: "MyProject.xcodeproj",
			.targetName: "MyProject",
			.configurationName: "Dev",
			.sdk: "iphoneos",
			.exportPlistPath: "./ExportOptionsPlist",
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenInvalidOptionSeparator_regexFindsMatchForScheme() throws {
		let givenShellScript = "xcodebuild archive -project=MyProject -scheme MyProject"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.schemeName: "MyProject"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenDoubleDashInOption_regexFindsMatchForAllOptionsFixingDash() throws {
		let givenShellScript = "xcodebuild archive --project MyProject -scheme MyProjectScheme"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.projectPath: "MyProject",
			.schemeName: "MyProjectScheme",
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenEmptyShellScript_regexFindsNoMatch() throws {
		let givenShellScript = ""
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [:]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenNoOptions_regexFindsNoMatch() throws {
		let givenShellScript = "xcodebuild archive "
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [:]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenOptionsBeyondCommandOptions_regexFindsNoMatch() throws {
		let givenShellScript = "xcodebuild archive -archivePath ./MyProject.xcarchive -json -arch arm64"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [:]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenSchemeWithSpace_regexFindsMatch() throws {
		let givenShellScript =
			"xcodebuild archive -project MyProject.xcodeproj -scheme My Project -configuration Dev -sdk iphoneos -archivePath ./MyProject.xcarchive | tee -a archive.txt -exportOptionsPlist ./ExportOptionsPlist"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.projectPath: "MyProject.xcodeproj",
			.schemeName: "My Project",
			.configurationName: "Dev",
			.sdk: "iphoneos",
			.exportPlistPath: "./ExportOptionsPlist",
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenExtraOpenBracketInsideShellScript_regexFindsMatchOmittingInvalidCharacter() throws {
		let givenShellScript =
			"xcodebuild archive -project MyProject.xcodeproj -scheme My Project { ^% -configuration Dev (-sdk iphoneos @ -archivePath ./MyProject.xcarchive | tee -a archive.txt #-exportOptionsPlist ./ExportOptionsPlist"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.projectPath: "MyProject.xcodeproj",
			.schemeName: "My Project",
			.configurationName: "Dev",
			.sdk: "iphoneos",
			.exportPlistPath: "./ExportOptionsPlist",
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenInvalidCharacterInSchemeUsingSpace_regexFindsMatchWithOnlyValidCharacters() throws {
		let givenShellScript = "-scheme My Project {"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.schemeName: "My Project"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenInvalidCharacterInSchemeAtTheEndWithoutSpace_regexFindsMatchWithOnlyValidCharacters() throws {
		let givenShellScript = "-scheme My Project{ "
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.schemeName: "My Project"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenInvalidCharacterInSchemeInTheMiddleWithoutSpace_regexFindsMatchWithOnlyValidCharacters() throws {
		let givenShellScript = "-scheme My{Project"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.schemeName: "My"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenInvalidCharacterInSchemeInTheMiddleWithSpace_regexFindsMatchWithOnlyValidCharacters() throws {
		let givenShellScript = "-scheme My {Project"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.schemeName: "My"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenDashInTheMiddleOfOption_regexFindsMatch() throws {
		let givenShellScript = "-exportOptionsPlist ./ExportOptionsPlist-Dir/exportOption.plist"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.exportPlistPath: "./ExportOptionsPlist-Dir/exportOption.plist"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}

	func test_givenDashInTheMiddleOfOptionTwice_regexFindsMatch() throws {
		let givenShellScript = "-exportOptionsPlist ./ExportOptionsPlist-Dir/export-Option.plist"
		let commandParser: BuildCommand = IosBuildCommand(shellScript: givenShellScript)
		let expectedCommandOptions: BuildCommandOptions = [
			.exportPlistPath: "./ExportOptionsPlist-Dir/export-Option.plist"
		]
		XCTAssertEqual(commandParser.commandOptions, expectedCommandOptions)
	}
}
