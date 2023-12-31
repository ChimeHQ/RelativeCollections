import RelativeCollectionsInternal

public struct RelativeArray<Value, Weight> where Weight : Comparable {
	public typealias Predicate = (Record, Index) -> Bool
	public typealias WeightOperator = (Weight, Weight) -> Weight
	private typealias Storage = ContiguousArray<Record>

	public struct WeightedValue {
		public var value: Value
		public var weight: Weight

		public init(value: Value, weight: Weight) {
			self.value = value
			self.weight = weight
		}
	}

	public struct Record {
		var weightedValue: WeightedValue
		public internal(set) var dependency: Weight

		init(value: Value, weight: Weight, dependency: Weight) {
			self.weightedValue = WeightedValue(value: value, weight: weight)
			self.dependency = dependency
		}

		init(weightedValue: WeightedValue, dependency: Weight) {
			self.weightedValue = weightedValue
			self.dependency = dependency
		}

		public var value: Value {
			get { weightedValue.value }
			set { weightedValue.value = newValue }
		}

		public var weight: Weight {
			get { weightedValue.weight }
			set { weightedValue.weight = newValue }
		}
	}

	private var storage: Storage
	let configuration: Configuration

	public init(configuration: Configuration) {
		self.storage = Storage()
		self.configuration = configuration
	}

	public init(_ slice: Slice<Self>) {
		self.storage = Storage(slice)
		self.configuration = slice.base.configuration
	}
}

extension RelativeArray {
	public struct Configuration {
		public let initial: Weight
		public let add: WeightOperator
		public let subtract: WeightOperator

		public init(initial: Weight, add: @escaping WeightOperator, subtract: @escaping WeightOperator) {
			self.initial = initial
			self.add = add
			self.subtract = subtract
		}
	}
}

extension RelativeArray.Configuration where Weight : AdditiveArithmetic {
	public init() {
		self.initial = Weight.zero
		self.add = { $0 + $1 }
		self.subtract = { $0 - $1 }
	}
}

extension RelativeArray where Weight : AdditiveArithmetic {
	public init() {
		self.init(configuration: .init())
	}
}

extension RelativeArray {
	private func findDependency(for position: Int) -> Weight {
		guard let record = storage[before: position] else {
			return configuration.initial
		}

		return configuration.add(record.weight, record.dependency)
	}

	private mutating func applyDelta(_ delta: Weight, after index: Index) {
		if delta == configuration.initial {
			return
		}

		applyDelta(delta, startingAt: storage.index(after: index))
	}

	private mutating func applyDelta(_ delta: Weight, startingAt index: Index) {
		if delta == configuration.initial {
			return
		}

		for updateIndex in index..<storage.endIndex {
			storage[updateIndex].dependency = configuration.add(storage[updateIndex].dependency, delta)
		}
	}

	/// Factors out the starting dependency from all stored records.
	///
	/// - Returns: The first record dependency, or the initial weight if the array is empty.
	@discardableResult
	public mutating func extractInitialDependency() -> Weight {
		guard let first = storage.first else {
			return configuration.initial
		}

		let initialDependency = first.dependency
		let delta = configuration.subtract(configuration.initial, initialDependency)

		applyDelta(delta, startingAt: storage.startIndex)

		return initialDependency
	}

	public mutating func subtract(_ weight: Weight) {
		for updateIndex in storage.indices {
			storage[updateIndex].dependency = configuration.subtract(storage[updateIndex].dependency, weight)
		}
	}
}

extension RelativeArray {
	public mutating func append(_ value: WeightedValue) {
		insert(value, at: endIndex)
	}

	public mutating func insert(_ value: WeightedValue, at index: Index) {
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

		let delta = configuration.subtract(configuration.initial, record.weight)

		applyDelta(delta, startingAt: index)

		return record
	}

	public mutating func replace(_ value: WeightedValue, at index: Index) {
		let current = storage[index]

		// overwrite it
		let previousWeight = findDependency(for: index)
		let record = Record(weightedValue: value, dependency: previousWeight)

		storage[index] = record

		// compute delta, and update affected records
		let delta = configuration.subtract(value.weight, current.weight)

		applyDelta(delta, after: index)
	}
}

extension RelativeArray where Weight : Comparable {
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

extension RelativeArray : Sequence {
	public struct Iterator: IteratorProtocol {
		private let array: RelativeArray
		private var index: RelativeArray.Index

		init(array: RelativeArray) {
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

extension RelativeArray : RandomAccessCollection {
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

extension RelativeArray {
	public mutating func replaceSubrange<Elements>(
		_ range: Range<Index>,
		with newElements: Elements
	) where WeightedValue == Elements.Element, Elements : Sequence {
		let previousWeight = findDependency(for: range.lowerBound)

		// create the new records and insert them
		var newRecords = [Record]()
		var dependency = previousWeight

		for element in newElements {
			let record = Record(weightedValue: element, dependency: dependency)
			newRecords.append(record)

			dependency = configuration.add(element.weight, dependency)
		}

		let originalDependency = findDependency(for: range.upperBound)

		storage.replaceSubrange(range, with: newRecords)

		let affectedIndex = range.lowerBound + newRecords.count
		if affectedIndex >= storage.endIndex {
			return
		}

		// and now, we have to adjust everything past the insertion

		let delta = configuration.subtract(dependency, originalDependency)

		applyDelta(delta, startingAt: affectedIndex)
	}
}

extension RelativeArray.WeightedValue : Equatable where Value : Equatable, Weight : Equatable {}
extension RelativeArray.WeightedValue : Hashable where Value : Hashable, Weight : Hashable {}
extension RelativeArray.WeightedValue : Sendable where Value : Sendable, Weight : Sendable {}

extension RelativeArray.WeightedValue : CustomDebugStringConvertible {
	public var debugDescription: String {
		"{\(self.value), \(self.weight)}"
	}
}

extension RelativeArray.WeightedValue where Value == Weight {
	public init(weight: Weight) {
		self.value = weight
		self.weight = weight
	}
}

extension RelativeArray.Record : Equatable where Value : Equatable, Weight : Equatable {}
extension RelativeArray.Record : Hashable where Value : Hashable, Weight : Hashable {}
extension RelativeArray.Record : Sendable where Value : Sendable, Weight : Sendable {}

extension RelativeArray.Record : CustomDebugStringConvertible {
	public var debugDescription: String {
		"{\(self.value), \(self.weight), \(self.dependency)}"
	}
}
