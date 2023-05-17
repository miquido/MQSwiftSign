import Foundation

extension Dictionary where Key == String, Value == [String] {
	var partitionsKey: String {
		"Partitions"
	}

	var defaultPartitions: [String] {
		["apple:", "apple-tool:", "codesign:"]
	}

	mutating func appendDefaultPartitions(with customPartitions: [String]) {
		var partitionsToAdd = defaultPartitions
		partitionsToAdd.append(contentsOf: customPartitions)
		for item in partitionsToAdd {
			var partitions = self[partitionsKey] ?? []
			if !partitions.contains(item) {
				partitions.append(item)
			}
			self[partitionsKey] = partitions
		}
	}

	func encodeBackIntoXmlData() throws -> Data {
		let format = PropertyListSerialization.PropertyListFormat.xml
		return try PropertyListSerialization.data(
			fromPropertyList: self,
			format: format,
			options: 0)
	}
}
