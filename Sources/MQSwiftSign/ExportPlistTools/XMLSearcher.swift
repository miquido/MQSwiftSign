import Foundation

internal final class XMLSearcher: NSObject, XMLParserDelegate {
	internal var searchClosure: ((String, Dictionary<String, String>) -> String?)?
	internal var searchResult: String? {
		didSet {
			if searchResult != nil {
				searchClosure = nil
			}
		}
	}

	init(searchClosure: @escaping (String, Dictionary<String, String>) -> String?) {
		self.searchClosure = searchClosure
		super.init()
	}

	internal func parser(
		_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
		qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
	) {
		guard let searchClosure = searchClosure else { return }
		searchResult = searchClosure(elementName, attributeDict)
	}
}

extension XMLSearcher {
	static var projectFileSearcher: Self {
		return .init { elementName, attributeDict in
			if elementName == "FileRef",
				let location = attributeDict["location"]
			{
				return location.replacingOccurrences(of: "group:", with: "")
			}
			return nil
		}
	}

	static var targetRefSearcher: Self {
		return .init { elementName, attributeDict in
			if elementName == "BuildableReference",
				let buildableName = attributeDict["BuildableName"],
				buildableName.hasSuffix(".app")
			{
				return attributeDict["BlueprintIdentifier"]
			}
			return nil
		}
	}

	static var configurationNameSearcher: Self {
		return .init { elementName, attributeDict in
			if elementName == "ArchiveAction" {
				return attributeDict["buildConfiguration"]
			}
			return nil
		}
	}

	func search(in url: URL) -> String? {
		let xmlParser = XMLParser(contentsOf: url)
		xmlParser?.delegate = self
		xmlParser?.parse()
		return self.searchResult
	}
}
