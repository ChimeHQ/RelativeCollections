public enum BinarySearchDirection: Hashable, Sendable {
	case ascending
	case descending
}

extension Collection {
	/// Returns the first index that satisifies the predicate and direction.
	///
	/// Search direction can be controlled with `direction`.
	/// - `.ascending`: predicate failure checks higher indexes
	/// - `.descending`: predicate failure checks lower indexes
	public func binarySearch(
		direction: BinarySearchDirection = .ascending,
		predicate: (Iterator.Element, Index) throws -> Bool
	) rethrows -> Index? {
		switch direction {
		case .ascending:
			try binarySearchAscending(predicate: predicate)
		case .descending:
			try binarySearchDescending(predicate: predicate)
		}
	}

	/// Returns the lowest index where the predicate returns true. A
	/// failure checks higher indexes.
	private func binarySearchAscending(predicate: (Iterator.Element, Index) throws -> Bool) rethrows -> Index? {
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

	/// Returns the highest index where the predicate returns true. A
	/// failure checks lower indexes.
	private func binarySearchDescending(predicate: (Iterator.Element, Index) throws -> Bool) rethrows -> Index? {
		var low = startIndex
		var high = endIndex

		while low != high {
			let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
			if try predicate(self[mid], mid) {
				low = index(after: mid)
			} else {
				high = mid
			}

			if low > high {
				return nil
			}
		}

		low = index(low, offsetBy: -1)
		if low < startIndex {
			return nil
		}

		return low
	}
}
