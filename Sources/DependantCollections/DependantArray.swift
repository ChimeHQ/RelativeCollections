import DependantCollectionsInternal

/// A sorted list that holds recursively-dependent values.
public struct DependantArray<Independent, Dependency, Value> where Value : Comparable {
	public typealias Decompose = (Value) -> Record
	public typealias Compose = (Record) -> Value
	public typealias Integrate = (Dependency, Dependency) -> Dependency
	public typealias Separate = (Dependency, Dependency) -> Dependency

	typealias List = ContiguousArray<Record>

	private var list: List
	let configuration: Configuration

	public init(configuration: Configuration) {
		self.list = List()
		self.configuration = configuration
	}
}

extension DependantArray {
	public struct Configuration {
		public let decompose: Decompose
		public let compose: Compose
		public let integrate: Integrate
		public let separate: Separate
		public let initial: Dependency

		public init(
			decompose: @escaping Decompose,
			compose: @escaping Compose,
			integrate: @escaping Integrate,
			separate: @escaping Separate,
			initial: Dependency
		) {
			self.decompose = decompose
			self.compose = compose
			self.integrate = integrate
			self.separate = separate
			self.initial = initial
		}
	}
}

extension DependantArray {
	public struct Record {
		public let independent: Independent
		public private(set) var dependency: Dependency

		public init(independent: Independent, dependency: Dependency) {
			self.independent = independent
			self.dependency = dependency
		}

		mutating func separate(_ previousDep: Dependency, using config: Configuration) {
			self.dependency = config.separate(previousDep, dependency)
		}

		mutating func integrate(_ newDep: Dependency, using config: Configuration) {
			self.dependency = config.integrate(newDep, dependency)
		}
	}
}

extension DependantArray {
	public mutating func insert(_ value: Value) {
		let newRecord = configuration.decompose(value)

		let idx = list.binarySearch { record, idx in
			let recomposed = configuration.compose(record)

			return recomposed < value
		} ?? list.endIndex

		list.insert(newRecord, at: idx)
	}

	public mutating func remove(at index: Index) {
		let record = list.remove(at: index)

		for updateIdx in index..<list.endIndex {
			list[updateIdx].separate(record.dependency, using: configuration)
		}
	}

	public mutating func append(_ value: Value) {
		let newRecord = configuration.decompose(value)

		if let last = self[before: endIndex] {
			precondition(value > last)
		}

		list.append(newRecord)
	}

	public func index<T: Comparable>(closestTo target: T, using transform: (Value) -> T) -> Index? {
		list.binarySearch { record, idx in
			let value = self[idx]
			let key = transform(value)

			return target < key
		}
	}
}

extension DependantArray : Sequence {
	public typealias Element = Value

	public struct Iterator: IteratorProtocol {
		public typealias Element = Value

		private let configuration: Configuration
		private var listIterator: List.Iterator

		init(listIterator: List.Iterator, configuration: Configuration) {
			self.listIterator = listIterator
			self.configuration = configuration
		}

		public mutating func next() -> Value? {
			guard let record = listIterator.next() else {
				return nil
			}

			return configuration.compose(record)
		}
	}

	public func makeIterator() -> Iterator {
		Iterator(listIterator: list.makeIterator(), configuration: configuration)
	}
}

extension DependantArray : MutableCollection, RandomAccessCollection {
	public typealias Index = Int

	public var startIndex: Index {
		list.startIndex
	}

	public var endIndex: Index {
		list.endIndex
	}

	private func findDependency(for position: Int) -> Dependency {
		list[before: position]?.dependency ?? configuration.initial
	}

	public subscript(position: Index) -> Value {
		_read {
			precondition(list.isEmpty == false)

			let record = list[position]
			let previous = findDependency(for: position)

			yield configuration.compose(Record(independent: record.independent, dependency: previous))
		}
		set(newValue) {
			precondition(list.isEmpty == false)
			
			let existing = list[position]
			let newRecord = configuration.decompose(newValue)
			let depDelta = configuration.separate(existing.dependency, newRecord.dependency)

			list[position] = newRecord

			let nextPos = list.index(after: position)

			if let before = list[before: position] {
				let beforeComposed = configuration.compose(before)

				precondition(newValue > beforeComposed)
			}

			for updateIdx in nextPos..<list.endIndex {
				list[updateIdx].integrate(depDelta, using: configuration)
			}
		}
	}

	public func index(after i: Index) -> Index {
		list.index(after: i)
	}
}

extension DependantArray.Record : Equatable where Independent : Equatable, Dependency : Equatable {}
extension DependantArray.Record : Hashable where Independent : Hashable, Dependency : Hashable {}
extension DependantArray.Record : Sendable where Independent : Sendable, Dependency : Sendable {}

extension DependantArray.Record : CustomDebugStringConvertible {
	public var debugDescription: String {
		"(\(self.independent), \(self.dependency))"
	}
}

extension DependantArray.Configuration where Dependency : AdditiveArithmetic {
	public init(decompose: @escaping DependantArray.Decompose, compose: @escaping DependantArray.Compose) {
		self.init(
			decompose: decompose,
			compose: compose,
			integrate: { $0 + $1 },
			separate: { $1 - $0 },
			initial: Dependency.zero
		)
	}
}
