SHELL := zsh
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:

# Load project configuration
include $(PWD)/project.env

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
	$(print_prepare)
	@$(MQSWIFTSIGN_DIR)/MQSwiftSign prepare $(prepare_keychain_subcommand_options)
	
cleanup:
	$(MQSWIFTSIGN_DIR)/MQSwiftSign cleanup

## PRIVATE

prepare_keychain_subcommand_options=$(CERT_CONTENT) $(CERT_PASSWORD_OPTION) $(KEYCHAIN_NAME_OPTION) $(KEYCHAIN_PASSWORD_OPTION) $(PROVISIONING_OPTION) $(CUSTOM_ACLS_OPTION) $(APPLICATIONS_OPTION)

._prepare_ios_auth:
	$(print_prepare_ios_auth)
	@mkdir ./private_keys && echo "$(ASC_KEY_CONTENT)" | base64 --decode > ./private_keys/AuthKey_$(ASC_KEY_ID).p8

._ios_prepare_and_build_with_export_plist:
	$(print_ios_prepare_and_build_with_export_plist)
	@$(MQSWIFTSIGN_DIR)/MQSwiftSign $(prepare_keychain_subcommand_options) $(DISTRIBUTION_METHOD_OPTION) --shell-script "xcodebuild archive $(PROJECT_OPTION) $(WORKSPACE_OPTION) $(SCHEME_OPTION) $(TARGET_IOS_OPTION) $(CONFIGURATION_OPTION) $(ARCHIVE_OPTION) $(SDK_OPTION) && xcodebuild -exportArchive $(ARCHIVE_OPTION) $(EXPORT_OPTION) $(IOS_EXPORT_OPTIONS_PLIST_OPTION)"

._flutter_prepare_and_build_with_export_plist:
	$(print_flutter_prepare_and_build_with_export_plist)
	@$(MQSWIFTSIGN_DIR)/MQSwiftSign $(prepare_keychain_subcommand_options) $(DISTRIBUTION_METHOD_OPTION) --shell-script "fvm flutter build ipa $(FLUTTER_BUILD_CONFIGURATION_OPTION) $(FLUTTER_FLAVOR_OPTION) $(FLUTTER_TARGET_OPTION) $(FLUTTER_BUILD_NUMBER_OPTION) $(FLUTTER_EXPORT_OPTIONS_PLIST_OPTION) "

._upload: ._prepare_ios_auth
	$(print_app_validation)
	$(print_app_upload)
	@xcrun altool --validate-app -f $(EXPORT_PATH)/*.ipa --apiKey $(ASC_KEY_ID) --apiIssuer $(ASC_KEY_ISSUER) --type ios
	@xcrun altool --upload-app -f $(EXPORT_PATH)/*.ipa --apiKey $(ASC_KEY_ID) --apiIssuer $(ASC_KEY_ISSUER) --type ios

# Makefile prints executed command by default, including resolved vars that should be kept secret. We do custom print instead to hide them
print_prepare=@echo $(MQSWIFTSIGN_DIR)/MQSwiftSign prepare $(print_options)
print_prepare_ios_auth=@echo "mkdir ./private_keys && echo <ASC_KEY_CONTENT> | base64 --decode > ./private_keys/AuthKey_<ASC_KEY_ID>.p8"
print_ios_prepare_and_build_with_export_plist=@echo $(MQSWIFTSIGN_DIR)/MQSwiftSign $(print_options) $(DISTRIBUTION_METHOD_OPTION) --shell-script "xcodebuild archive $(PROJECT_OPTION) $(WORKSPACE_OPTION) $(SCHEME_OPTION) $(TARGET_IOS_OPTION) $(CONFIGURATION_OPTION) $(ARCHIVE_OPTION) $(SDK_OPTION) && xcodebuild -exportArchive $(ARCHIVE_OPTION) $(EXPORT_OPTION) $(IOS_EXPORT_OPTIONS_PLIST_OPTION)"
print_flutter_prepare_and_build_with_export_plist=@echo $(MQSWIFTSIGN_DIR)/MQSwiftSign $(print_options) $(DISTRIBUTION_METHOD_OPTION) --shell-script "fvm flutter build ipa $(FLUTTER_BUILD_CONFIGURATION_OPTION) $(FLUTTER_FLAVOR_OPTION) $(FLUTTER_TARGET_OPTION) $(FLUTTER_BUILD_NUMBER_OPTION) $(FLUTTER_EXPORT_OPTIONS_PLIST_OPTION)"
print_app_validation=@echo "xcrun altool --validate-app -f $(EXPORT_PATH)/*.ipa --apiKey <ASC_KEY_ID> --apiIssuer <ASC_KEY_ISSUER> --type ios"
print_app_upload=@echo "xcrun altool --upload-app -f $(EXPORT_PATH)/*.ipa --apiKey <ASC_KEY_ID> --apiIssuer <ASC_KEY_ISSUER> --type ios"
print_options=$(if $(CERT_CONTENT), "<CERT_CONTENT>") $(if $(CERT_PASSWORD), --cert-password "<CERT_PASSWORD>") $(KEYCHAIN_NAME_OPTION) $(if $(KEYCHAIN_PASSWORD), --keychain-password "<KEYCHAIN_PASSWORD>") $(PROVISIONING_OPTION) $(CUSTOM_ACLS_OPTION) $(APPLICATIONS_OPTION)
