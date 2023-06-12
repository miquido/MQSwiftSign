import Darwin

enum TerminationSignal: CaseIterable {
	case terminate  // standard way to terminate app, i.e. `kill <pid>`
	case interrupt  // program interrupt - i.e. CTRL+c in terminal
	case quit  // quit, i.e. CTRL+\ in terminal
	case kill  // process killed - cannot be caught. i.e. `kill -9 <pid>`
	case hangUp  // terminal disconnected, i.e. network connection broken

	var systemSignal: Int32 {
		switch self {
		case .terminate:
			return SIGTERM
		case .interrupt:
			return SIGINT
		case .quit:
			return SIGQUIT
		case .kill:
			return SIGKILL
		case .hangUp:
			return SIGHUP
		}
	}
}

extension TerminationSignal {
	typealias SignalHandler = @convention(c) (Int32) -> Void

	func handle(withAction action: SignalHandler) {
		signal(systemSignal, action)
	}
}

extension Array where Element == TerminationSignal {
	func handle(withAction action: TerminationSignal.SignalHandler) {
		forEach { signal in
			signal.handle(withAction: action)
		}
	}
}
