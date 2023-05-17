# MQSwiftSign

A tool that facilitates development of your native iOS, Flutter and React Native applications by preparing your macOS environment to be ready for Xcode to build and codesign your application.

The main uses of this tool are CI systems, but you can use it as well on your daily development setup.

## Features:

1. Keychain preparation, which consists of:
	- Check out for any previous keychain leftovers and if there are any, remove them.
	- Decode provided base64 certificate data into structure that can be later imported into the keychain.
	- Create temporary keychain with specified name, unlocked and with password prompt turned off.
	- Install certificate into just created keychain.
	- Add temporary keychain to the keychain searchlist.
	- Set up proper access options for the certificate.
2. Installation of any provisioning profile found in specified path, making it visible for Xcode. See [installing provisioning profiles](#installing-provisioning-profiles) for more information.
3. Execution of a provided shell script.
4. Composition of an export plist from build options provided in shell script. See [creating options plist](#creating-export-plist) for more information.
5. Cleanup of any used resources, restoring environment to its neutral state.

Basically, it does the same work as `fastlane match`, but stripped of unnecessary bloatware and rubygem dependencies, making it swift and clean.

> NOTE: It is your responsibility to provide proper certificate for the build. The tool doesn't check if the certificate you're trying to import matches your build type; If you're trying to codesign e.g. Testflight build using development certificate, be aware that build will fail on the codesign step. Check in Xcode which certificate you use for particular build configuration and export it. 
The same rule applies to provided provisioning profiles - if using the tool with --provisioningPath option, profiles have to match selected project configuration, because the tool will just install any profile contained in provided directory. If wrong provisioning profile is provided, the build command will fail as well.

## Usage

For your convenience, we packed the usage of the tool into the [makefile](./Makefile) and bundled it up with most common use cases of the tool. It covers binary building, unit tests, app building & uploading it to Testflight.

The makefile is prepared to run on any macOS with Xcode installed. The only thing to be done is to provide required variables, and you are ready to go! 

### Package or executable?

You can use the tool as swift package or as standalone binary. The standalone binary is recommended way, and all examples are set up with assumption that you use standalone binary.

To build a standalone binary, run `make build_universal_binary` in the main directory. This will build a binary and place it in the main directory (under `./MQSwiftSign`). Note that this action will build a fat binary, which will run on both Intel and Apple Sillicon processors. If you don't need a fat binary, just strip unnecessary arch from `build_universal_binary` action.

However, if you find yourself in need of swift package use (e.g. you have to customize its behavior, or incorporate it into your custom swift package setup) then replace in examples `./MQSwiftSign` with `swift run --package-path <path_to_MQSwiftSign>`.


### Detailed usage

#### With makefile

In the makefile, set up required variables and execute action: 

```
make ios_build_and_upload
```

or 

```
make flutter_build_and_upload
```

The tool will automatically prepare, build and upload your iOS application to Testflight - no more work required!

> NOTE: For React Native applications you should use native iOS actions.

Check out the [makefile](./Makefile) to see more actions and details of usage.

#### Without makefile

If, for some reason, you don't want to use Makefile, you can use the tool directly. Detailed description of tool parameters can be found [below](#tool-command-parameters). 

The tool provides two subcommands: 

1. `prepare` which sets up the keychain ready for codesigning
2. `cleanup` which cleans up resources used by the script. 

Please note, that in this mode, you can't use the `--distribution-method` parameter, as the tool doesn't have the project configuration context to compose Export.plist from.

##### Samples of non-makefile usage:

- Preparing keychain for build:

```
./MQSwiftSign prepare $CERT_CONTENT --cert-password $CERT_PASSWORD <other_arguments_if_needed>
```

- Cleaning up after build:
```
./MQSwiftSign cleanup
```

- Full flutter build setup: 

```
./MQSwiftSign prepare $CERT_CONTENT --cert-password $CERT_PASSWORD --keychain-name $KEYCHAIN_NAME --keychain-password $KEYCHAIN_PASSWORD --provisioning-path "../Provisionings/"
flutter build ipa --release --export-options-plist=./export.plist
./MQSwiftSign cleanup
```

- Full iOS/React Native build setup: 
```
./MQSwiftSign prepare $CERT_CONTENT --cert-password $CERT_PASSWORD --keychain-name $KEYCHAIN_NAME --keychain-password $KEYCHAIN_PASSWORD --provisioning-path "../Provisionings/"
xcodebuild archive -project MyProject.xcodeproj -scheme SchemeName -configuration ConfigurationName -archivePath ./MyProject.xcarchive -destination 'generic/platform=iOS'
xcodebuild -exportArchive -archivePath ./MyProject.xcarchive -exportPath ./artifact -exportOptionsPlist export.plist -destination 'generic/platform=iOS'
./MQSwiftSign cleanup
```

### Tool command parameters

You can get these informations running `./MQSwiftSign --help` as well.

> NOTE: It is recommended to not provide sensitive data, in particular cert content or cert password, directly, but rather to pass it using env vars.

#### Required:

`--cert-content`: Argument. Base64 encoded certificate content. You can get one by calling `cat <cert_file>.p12 | base64`.

#### Optional parameters: 

`--cert-password`: Password to decrypt certificate. This is the same password you have used to export certificate from your keychain. Empty string by default or if omitted.

`--keychain-name`: Name of the temporary keychain file used to store cert for the building time.

Although tool will use random generated string for this if not provided, it is recommended to provide your own name e.g. based on project name, you might want to provide one for debugging purposes.

> NOTE: If you have been using that property already and you plan to change keychain name to another one, it is recommended to call `cleanup` action first, before preparing keychain with the new name - to make sure that there are no leftovers in the system.

`--keychain-password`: password for the temporary keychain.

The tool will use random generated UUID based password if not provided, however, you might want to provide one for debugging purposes.

#### Optional actions:

`--shell-script`: Script to be executed after keychain creation. Intended to contain build commands for particular platform. If provided, after execution of the script, tool will clean up any used resources.

`--provisioning-path`: Relative path to a directory which contains provisioning profiles to be installed. If not provided, the default path is current process working directory path.

For more info, please see [installing provisioning profiles](#installing-provisioning-profiles).

`--distribution-method`: The app distribution method. If this parameter is provided along with the `--shell-script` argument, and build commands are included in the script, the tool will attempt to extract necessary information from the project file. The resulting plist file will be generated at the path specified in the build command options. If no path is provided, a default path will be used.

> NOTE: If this parameter is omitted then no export plist file will be created. Valid distribution methods are: validation, package, enterprise, development, app-store, ad-hoc, development-id, mac-application.

For more info, please see [creating options plist](#creating-export-plist).

#### Misc

`--custom-acls`: Custom ACL groups/partitions to which access to the imported certificate will be granted.

`--applications`: Absolute paths to apps that are allowed access to the imported certificate without user confirmation.

## Additional features
As an addition to importing certificates, the tool provides features described below.

### Installing provisioning profiles
To install provisioning profiles the `--provisioning-path` should point at a **directory** that contains those provisioning profiles.
The tool searches there for all `*.mobileprovision` files in that directory and copies them to the `~/Library/MobileDevices/Provisioning Profiles/` directory. 
While copying files the tool takes the UUID from each provisioning profile and uses it as destination file's name.

### Creating export plist
The tool can create and export plist file with the project's configuration if needed. To create the export plist the following conditions should be satisfied:
1. The `--shell-script` parameter must contain a proper build command (`xcodebuild`, `flutter build` etc)
2. The `--distribution-method` parameter must be given
For example of that, please see `ios_build_and_upload` action from [makefile](./Makefile). 

If you use makefile actions, the tool will take care of that for you.

The export plist content is created based on the project configuration and the given `--distribution-method`. 
For `xcodebuild` command, it must contain the following parameters:
- `-project` or `-workspace` in order to fetch project/workspace content like targets and dependencies
- either `-scheme` or `-target` in order to fetch build settings (sign style, team ID, provisioning profile specifiers etc.) based on the given configuration - if configuration is not provided, the default one will be inferred
- `-exportOptionsPlist` for fetching the path at which the export plist file should be saved.
- an optional `-sdk` if the project has multiple destination platforms (iOS, iPadOS, tvOS)
For the `flutter build` command, tool anticipates the default scheme and target name for iOS builds (which is `Runner`) and executes similar actions as in `xcodebuild` case.

The tool supports nested dependencies - meaning, if your project uses separate app extension (for WatchOS, Rich Notifications etc.) the output plist will support it.

If needed (see the above conditions) MQSwiftSign tries in first place to create the export option plist and then runs the given `--shell-script`. This way, while executing the build command, the export option plist is already created and saved at the specified path.   

Note that this parameter is only available when using makefile's actions. When using subcommands, the tool has no project configuration context to create a plist from.

## License

Copyright 2023 Miquido

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
