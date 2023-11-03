extension Collection {
	/// Returns the first index that satisifies the predicate.
	///
	/// A predicate failure will check higher indexes.
	public func binarySearch(
		predicate: (Iterator.Element, Index) throws -> Bool
	) rethrows -> Index? {
		var low = startIndex
		var high = endIndex

		while low != high {
			let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
			if try predicate(self[mid], mid) {
				high = mid
			} else {
				low = index(after: mid)
			}

			if low > high {
				return nil
			}
		}

		if low == endIndex {
			return nil
		}

		return low
	}
}
