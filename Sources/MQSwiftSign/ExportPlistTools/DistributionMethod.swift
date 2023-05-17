import Foundation

internal enum DistributionMethod: String {
	case validation = "validation"
	case package = "package"
	case enterprise = "enterprise"
	case development = "development"
	case appStore = "app-store"
	case adHoc = "ad-hoc"
	case developmentId = "development-id"
	case macApplication = "mac-application"
}
