extension Collection {
	public func indexRangeSatisifying(_ predicate: (Element) throws -> Bool) rethrows -> Range<Index> {
		return startIndex..<endIndex
	}
}
