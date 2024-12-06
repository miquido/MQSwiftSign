import MQDo

extension FeaturesRegistry {
	mutating func useExportPlistTools() {
		use(ExportPlistCreator.self)
		use(ExportOptionsWriter.system())
		use(ExportOptionsExtractor.xcodeProj())
		use(XcodeProjOptionsExtractor.live())
		use(XcodeProjFinder.live())
        use(DependencyTreeBuilder.live())
	}
}
