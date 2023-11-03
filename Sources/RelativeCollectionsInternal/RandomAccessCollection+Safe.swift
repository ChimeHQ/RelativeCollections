import Foundation

extension RandomAccessCollection {
	public subscript(before position: Index) -> Element? {
		if position <= startIndex || position > endIndex {
			return nil
		}

		let prevIdx = index(before: position)

		return self[prevIdx]
	}

	public subscript(after position: Index) -> Element? {
		if position < startIndex || position >= endIndex {
			return nil
		}

		let prevIdx = index(after: position)

		return self[safe: prevIdx]
	}

	public subscript(safe position: Index) -> Element? {
		if position < startIndex || position >= endIndex {
			return nil
		}

		return self[position]
	}

	public var lastIndex: Index? {
		let prevIdx = index(before: endIndex)

		if prevIdx < startIndex {
			return nil
		}

		return prevIdx
	}
}
