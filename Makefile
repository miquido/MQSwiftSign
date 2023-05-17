SHELL := zsh
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:

###################### VARIABLES ######################
# You can provide those vars directly or by using $(ENV_VARS). In some cases you **should** provide them by env vars (e. g. cert content).
# Not all of them are required; if any of these don't suit your needs, just omit it.
# If not provided, an argument for the absent value will not be set for the execution (see PARAMETER SETTING).

## Path to the binary file (default is the output of build_universal_binary action):
MQSWIFTSIGN_DIR=./

##### TESTING ##### 

## Testing device name and iOS version, e.g. iOS Simulator,name=iPhone 14,OS=16.2
TEST_PLATFORM=
## Scheme on which the test action will be executed
TEST_SCHEME=

##### UPLOAD #####
# Required if you want to upload your binary to Testflight.

## ID of the API key; you can generate one here: https://appstoreconnect.apple.com/access/api. This is the alphanumerical part of the generated file name AuthKey_XXXXXXX.p8
ASC_KEY_ID=
## Issuer id; visible on https://appstoreconnect.apple.com/access/api
ASC_KEY_ISSUER=
## Base64'd content of the .p8 key file.
ASC_KEY_CONTENT=

##### MQSwiftSign Options #####
# Also available under --help command and in README.md
CERT_CONTENT=
CERT_PASSWORD=
KEYCHAIN_NAME=
KEYCHAIN_PASSWORD=
PROVISIONING_PATH=
DISTRIBUTION_METHOD=
CUSTOM_ACLS=
APPLICATIONS=

##### BUILD OPTIONS - IOS & REACT NATIVE #####
# Required only for iOS and React Native actions.
# `--shell-script` argument will be executed with `xcodebuild archive` using those parameters.
# Providing (-workspacePath and -schemeName) or (-projectPath and -targetName) or (-projectPath and -schemeName) is enough.
PROJECT_PATH=
IOS_TARGET_NAME=

WORKSPACE_PATH=
SCHEME_NAME=

# If not provided, the default one is taken from project config
CONFIGURATION_NAME=
# To workaround Xcode's habit to build against first available target -  which in many cases is a macos application
SDK=iphoneos
# Specifies the path for the archive produced. If not provided, default path will be: ~/Library/Developer/Xcode/Archives/<year>-<month>-<day>
# It is strongly recommended to provide this path if you want later to export it to IPA.
ARCHIVE_PATH=./archives/archive.xcarchive

##### BUILD OPTIONS - FLUTTER #####
# Required only for Flutter actions.

# Build configuration, release by default.
FLUTTER_BUILD_CONFIGURATION=release

# If provided, it will be also used to provide target main file (under path /lib/main_$(FLAVOR_NAME).dart)
FLAVOR_NAME=

# If not provided, the defaults from project configurations are taken
BUILD_NUMBER=

#### BUILD OPTIONS - COMMON #####
# Common options for all platforms.
# If DISTRIBUTION_METHOD paremeter is provided, but this parameter isn't, plist will be created from project settings using default paths - Flutter: ./ios/ExportOptionsPlists/exportOption.plist, iOS: ./ExportOptionsPlists/exportOption.plist 
# If DISTRIBUTION_METHOD paremeter is not provided, but this parameter is, then you should provide export plist in provided path manually.
EXPORT_OPTIONS_PLIST_PATH=
# Specifies the destination path for the exported ipa, rather than the exact location for the generated file. During upload, altool will pick up anything with the .ipa extension in defined path.
EXPORT_PATH=


###################### PARAMETER SETTING - DO NOT EDIT UNLESS YOU ADD OR EDIT VARIABLES ######################

$(eval CERT_PASSWORD_OPTION := $(if $(CERT_PASSWORD), --cert-password $(CERT_PASSWORD)))
$(eval KEYCHAIN_NAME_OPTION := $(if $(KEYCHAIN_NAME), --keychain-name $(KEYCHAIN_NAME)))
$(eval KEYCHAIN_PASSWORD_OPTION := $(if $(KEYCHAIN_PASSWORD), --keychain-password $(KEYCHAIN_PASSWORD)))

$(eval PROVISIONING_OPTION := $(if $(PROVISIONING_PATH), --provisioning-path $(PROVISIONING_PATH)))
$(eval DISTRIBUTION_METHOD_OPTION := $(if $(DISTRIBUTION_METHOD), --distribution-method "$(DISTRIBUTION_METHOD)"))

$(eval PROJECT_OPTION := $(if $(PROJECT_PATH), -project $(PROJECT_PATH)))
$(eval WORKSPACE_OPTION := $(if $(WORKSPACE_PATH), -workspace $(WORKSPACE_PATH)))
$(eval SCHEME_OPTION := $(if $(SCHEME_NAME), -scheme $(SCHEME_NAME)))
$(eval TARGET_IOS_OPTION := $(if $(IOS_TARGET_NAME), -target $(IOS_TARGET_NAME)))
$(eval CONFIGURATION_OPTION := $(if $(CONFIGURATION_NAME), -configuration $(CONFIGURATION_NAME)))
$(eval SDK_OPTION := $(if $(SDK), -sdk $(SDK)))
$(eval ARCHIVE_OPTION := $(if $(ARCHIVE_PATH), -archivePath $(ARCHIVE_PATH)))
$(eval EXPORT_OPTION := $(if $(EXPORT_PATH), -exportPath $(EXPORT_PATH)))

$(eval FLUTTER_BUILD_CONFIGURATION_OPTION := $(if $(FLUTTER_BUILD_CONFIGURATION), --$(FLUTTER_BUILD_CONFIGURATION)))
$(eval FLUTTER_FLAVOR_OPTION := $(if $(FLAVOR_NAME), --flavor $(FLAVOR_NAME)))
$(eval FLUTTER_TARGET_OPTION := $(if $(FLAVOR_NAME), --target lib/main_$(FLAVOR_NAME).dart))
$(eval FLUTTER_BUILD_NUMBER_OPTION := $(if $(BUILD_NUMBER), --build-number=$(BUILD_NUMBER)))

$(eval IOS_EXPORT_OPTIONS_PLIST_OPTION := $(if $(EXPORT_OPTIONS_PLIST_PATH), -exportOptionsPlist $(EXPORT_OPTIONS_PLIST_PATH)))
$(eval FLUTTER_EXPORT_OPTIONS_PLIST_OPTION := $(if $(EXPORT_OPTIONS_PLIST_PATH), --export-options-plist=$(EXPORT_OPTIONS_PLIST_PATH)))

$(eval CUSTOM_ACLS_OPTION := $(if $(CUSTOM_ACLS), --custom-acls $(CUSTOM_ACLS)))
$(eval APPLICATIONS_OPTION := $(if $(APPLICATIONS), --applications $(APPLICATIONS)))


###################### MAKE ACTIONS ######################

## PUBLIC

build_universal_binary:
	swift build -c debug --arch arm64 --arch x86_64
	cp .build/apple/Products/Debug/MQSwiftSign ./
    
ios_test:
	xcodebuild $(PROJECT_OPTION) $(WORKSPACE_OPTION) -scheme $(TEST_SCHEME) -destination 'platform=$(TEST_PLATFORM)' test

flutter_test:
	fvm flutter test

ios_build_and_upload: \
	._ios_prepare_and_build_with_export_plist \
	._upload

flutter_build_and_upload: \
	._flutter_prepare_and_build_with_export_plist \
	._upload
	
prepare:
	$(MQSWIFTSIGN_DIR)/MQSwiftSign prepare $(prepare_keychain_subcommand_options)
	
cleanup:
	$(MQSWIFTSIGN_DIR)/MQSwiftSign cleanup

## PRIVATE 

prepare_keychain_subcommand_options=$(CERT_CONTENT) $(CERT_PASSWORD_OPTION) $(KEYCHAIN_NAME_OPTION) $(KEYCHAIN_PASSWORD_OPTION) $(PROVISIONING_OPTION) $(CUSTOM_ACLS_OPTION) $(APPLICATIONS_OPTION)

._prepare_ios_auth:
	mkdir ./private_keys && echo "$(ASC_KEY_CONTENT)" | base64 --decode > ./private_keys/AuthKey_$(ASC_KEY_ID).p8

._ios_prepare_and_build_with_export_plist:
	$(MQSWIFTSIGN_DIR)/MQSwiftSign $(prepare_keychain_subcommand_options) $(DISTRIBUTION_METHOD_OPTION) --shell-script "xcodebuild archive $(PROJECT_OPTION) $(WORKSPACE_OPTION) $(SCHEME_OPTION) $(TARGET_IOS_OPTION) $(CONFIGURATION_OPTION) $(ARCHIVE_OPTION) $(SDK_OPTION) && xcodebuild -exportArchive $(ARCHIVE_OPTION) $(EXPORT_OPTION) $(IOS_EXPORT_OPTIONS_PLIST_OPTION)"

._flutter_prepare_and_build_with_export_plist:
	$(MQSWIFTSIGN_DIR)/MQSwiftSign $(prepare_keychain_subcommand_options) $(DISTRIBUTION_METHOD_OPTION) --shell-script "fvm flutter build ipa $(FLUTTER_BUILD_CONFIGURATION_OPTION) $(FLUTTER_FLAVOR_OPTION) $(FLUTTER_TARGET_OPTION) $(FLUTTER_BUILD_NUMBER_OPTION) $(FLUTTER_EXPORT_OPTIONS_PLIST_OPTION) "

._upload: ._prepare_ios_auth
	xcrun altool --validate-app -f $(EXPORT_PATH)/*.ipa --apiKey $(ASC_KEY_ID) --apiIssuer $(ASC_KEY_ISSUER) --type ios
	xcrun altool --upload-app -f $(EXPORT_PATH)/*.ipa --apiKey $(ASC_KEY_ID) --apiIssuer $(ASC_KEY_ISSUER) --type ios
