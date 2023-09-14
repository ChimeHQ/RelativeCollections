public struct DependantArray<Value, Weight> where Weight : AdditiveArithmetic {
	public typealias Predicate = (Record, Index) -> Bool
	private typealias Storage = ContiguousArray<Record>

	public struct WeightedValue {
		public let value: Value
		public let weight: Weight

		public init(value: Value, weight: Weight) {
			self.value = value
			self.weight = weight
		}
	}

	public struct Record {
		public let value: Value
		public let weight: Weight
		public internal(set) var dependency: Weight
	}

	private var storage = Storage()

	public init() {
	}
}

extension DependantArray {
	private func findDependency(for position: Int) -> Weight {
		guard let record = storage[before: position] else {
			return Weight.zero
		}

		return record.weight + record.dependency
	}

	private mutating func applyDelta(_ delta: Weight, after index: Index) {
		if delta == Weight.zero {
			return
		}

		applyDelta(delta, startingAt: storage.index(after: index))
	}

	private mutating func applyDelta(_ delta: Weight, startingAt index: Index) {
		if delta == Weight.zero {
			return
		}

		for updateIndex in index..<storage.endIndex {
			storage[updateIndex].dependency += delta
		}
	}
}

extension DependantArray {
	public mutating func append(_ value: WeightedValue) {
		let idx = storage.endIndex

		insert(value, at: idx)
	}

	private mutating func insert(_ value: WeightedValue, at index: Index) {
		let previousWeight = findDependency(for: index)

		let record = Record(value: value.value, weight: value.weight, dependency: previousWeight)

		storage.insert(record, at: index)

		let delta = value.weight 

		applyDelta(delta, startingAt: storage.index(after: index))
	}

	public func record(at index: Index) -> Record {
		let previousWeight = findDependency(for: index)
		let record = storage[index]

		return Record(value: record.value, weight: record.weight, dependency: previousWeight)
	}

	@discardableResult
	public mutating func remove(at index: Index) -> Record {
		let record = storage[index]

		storage.remove(at: index)

		let delta = Weight.zero - record.weight

		applyDelta(delta, startingAt: index)

		return record
	}

	public mutating func replace(_ value: WeightedValue, at index: Index) {
		let current = storage[index]

		// overwrite it
		let previousWeight = findDependency(for: index)
		let record = Record(value: value.value, weight: value.weight, dependency: previousWeight)

		storage[index] = record

		// compute delta, and update affected records
		let delta = value.weight - current.weight

		applyDelta(delta, after: index)
	}
}

extension DependantArray where Weight : Comparable {
	public mutating func insert(_ value: WeightedValue, using predicate: Predicate) {
		let idx = storage.binarySearch(predicate: predicate) ?? storage.endIndex

		insert(value, at: idx)
		
		// now, verify that the array is still in sorted order
		let insertedDep = storage[idx].dependency

		if let previousDep = storage[before: idx]?.dependency {
			precondition(insertedDep > previousDep)
		}

		if let nextDep = storage[after: idx]?.dependency {
			precondition(nextDep > insertedDep)
		}
	}
}

extension DependantArray : Sequence {
	public struct Iterator: IteratorProtocol {
		private let array: DependantArray
		private var index: DependantArray.Index

		init(array: DependantArray) {
			self.array = array
			self.index = array.startIndex
		}

		public mutating func next() -> Record? {
			if index >= array.endIndex {
				return nil
			}

			let record = array.record(at: index)

			self.index = array.index(after: index)

			return record
		}
	}

	public func makeIterator() -> Iterator {
		Iterator(array: self)
	}
}


extension DependantArray : RandomAccessCollection {
	public typealias Index = Int

	public var startIndex: Index {
		storage.startIndex
	}

	public var endIndex: Index {
		storage.endIndex
	}

	public func index(after i: Index) -> Index {
		storage.index(after: i)
	}

	public subscript(position: Index) -> Record {
		_read {
			yield storage[position]
		}
	}
}

extension DependantArray.WeightedValue : Equatable where Value : Equatable {}
extension DependantArray.WeightedValue : Hashable where Value : Hashable, Weight : Hashable {}
extension DependantArray.WeightedValue : Sendable where Value : Sendable, Weight : Sendable {}

extension DependantArray.WeightedValue : CustomDebugStringConvertible {
	public var debugDescription: String {
		"{\(self.value), \(self.weight)}"
	}
}

extension DependantArray.Record : Equatable where Value : Equatable {}
extension DependantArray.Record : Hashable where Value : Hashable, Weight : Hashable {}
extension DependantArray.Record : Sendable where Value : Sendable, Weight : Sendable {}

extension DependantArray.Record : CustomDebugStringConvertible {
	public var debugDescription: String {
		"{\(self.value), \(self.weight), \(self.dependency)}"
	}
}
