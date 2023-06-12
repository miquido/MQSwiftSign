import Foundation
import MQDo

protocol MQSwiftSignCommand {
	mutating func run(_ features: Features) throws
}

struct MQSwiftSignCommandFactory {
	var prepare: (MQSwiftSign.PrepareOptions) -> MQSwiftSignCommand
	var cleanup: () -> MQSwiftSignCommand
}

extension MQSwiftSignCommandFactory: DisposableFeature {
	static var placeholder: MQSwiftSignCommandFactory {
		MQSwiftSignCommandFactory(
			prepare: unimplemented1(),
			cleanup: unimplemented0()
		)
	}
}

extension MQSwiftSignCommandFactory {
	static func `default`() -> FeatureLoader {
		.disposable { features in
			MQSwiftSignCommandFactory(
				prepare: { options in
					MQSwiftSign.Prepare(prepareOptions: options)
				},
				cleanup: {
					MQSwiftSign.Cleanup()
				}
			)
		}
	}
}
