extension Collection {
	/// Divide the collection into two equal parts.
	public func halve() -> (SubSequence, SubSequence) {
		// bias towards making the left side larger
		let middle = (Double(count) / 2.0).rounded(.up)
		let splitIndex = index(startIndex, offsetBy: Int(middle))

		let left = self[startIndex..<splitIndex]
		let right = self[splitIndex..<endIndex]

		return (left, right)
	}
}
