import DependantCollectionsInternal

/// A data structure that supports efficient storage of order-relative keys and values.
///
///	Data(0) = Value(0)
///	Data(1) = Value(1), Key(0)
///	Data(2) = Value(2), Key(0) + Key(1)
/// Data(N) = Value(N), Sum(Key(0) ... Key(N-1))
public final class DeltaList<Key, Value> where Key : Comparable, Key : AdditiveArithmetic {
	public typealias KeyTransform<T: Comparable> = (Key) -> T

	private var root = Node()
	let order: Int

	public init(order: Int) {
		self.order = order
	}
}

extension DeltaList {
	public struct Record {
		public private(set) var key: Key
		public let value: Value

		public init(key: Key, value: Value) {
			self.key = key
			self.value = value
		}

		mutating func transformDown(keySum: Key) {
			self.key = key - keySum
		}
	}
}

extension DeltaList.Record: Equatable where Value : Equatable {}
extension DeltaList.Record: Sendable where Key : Sendable, Value : Sendable {}

extension DeltaList.Record: CustomDebugStringConvertible {
	public var debugDescription: String {
		"(\(key), \(value))"
	}
}

extension DeltaList {
	public func insert(_ record: Record) {
		var keySum = Key.zero

		let query: KeyTransform = { $0 }

		let node = findLeaf(in: root, keySum: &keySum, using: query)

		guard case var .leaf(leaf) = node.kind else { preconditionFailure() }

		leaf.insert(record, key: keySum)

		print("leaf: ", leaf)

		node.kind = .leaf(leaf)
	}

	public func insert(_ value: Value, for key: Key) {
		insert(Record(key: key, value: value))
	}
}

extension DeltaList {
	@discardableResult
	func remove(_ key: Key) -> Bool {
		return false
	}
}

extension DeltaList {
	public typealias Index = Int

	public func index<T: Comparable>(of value: T, using transform: KeyTransform<T>) -> Index? {
		return nil
	}

	public func lookup<T: Comparable>(_ value: T, using transform: KeyTransform<T>) -> Record? {
		var keySum = Key.zero

		let node = findLeaf(in: root, keySum: &keySum, using: transform)

		guard case let .leaf(leaf) = node.kind else { preconditionFailure() }

		guard let idx = leaf.index(of: value, keySum: keySum, using: transform) else {
			return nil
		}

		return leaf.resolvedRecord(at: idx, with: keySum)
	}

	private func findLeaf<T: Comparable>(in node: Node, keySum: inout Key, using transform: KeyTransform<T>) -> Node {
		switch node.kind {
		case .leaf:
			return node
		case .internalNode:
			fatalError()
		}
	}
}

extension DeltaList {
	struct Leaf {
		var records: [Record]
		var next: Node?

		var count: Int {
			records.count
		}

		func resolvedKey(at index: Int, keySum: Key) -> Key {
			if index == 0 {
				return keySum
			}

			let previousRecord = records[index - 1]

			return keySum + previousRecord.key
		}

		func resolvedRecord(at index: Int, with key: Key) -> Record {
			let record = records[index]
			let sum = resolvedKey(at: index, keySum: key)

			return Record(key: record.key + sum, value: record.value)
		}

		func index<T: Comparable>(of value: T, keySum: Key, using transform: KeyTransform<T>) -> Int? {
			records.binarySearch { _, i in
				let resolved = resolvedRecord(at: i, with: keySum)

				return value < transform(resolved.key)
			}
		}

		mutating func insert(_ record: Record, key: Key) {
			let idx = index(of: record.key, keySum: key, using: { $0 }) ?? records.endIndex

			records.insert(record, at: idx)
//			let keyDiff = record.key - records[idx - 1].key

//			records.insert(Record(key: keyDiff, value: record.value), at: idx)
		}
	}
}

extension DeltaList {
	struct Internal {
	}
}

extension DeltaList {
	final class Node {
		enum Kind {
			case internalNode(Internal)
			case leaf(Leaf)
		}

		var kind: Kind = .leaf(Leaf(records: []))
	}
}
