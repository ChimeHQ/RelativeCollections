/// A B+Tree that can store dependent state from preceding elements.
public final class DPlusTree<Key: Comparable, DependentValue, Value> {
	public typealias CombineDependents = (_ lhs: DependentValue, _ rhs: DependentValue) -> DependentValue
	public typealias KeyFromDependent = (_ dependent: DependentValue) -> Key
	public typealias Query<T: Comparable> = (DependentValue) -> T

	let configuration: Configuration

	private var root: Node

	public init(configuration: Configuration) {
		self.configuration = configuration
		self.root = Node()
	}
}

extension DPlusTree {
	public struct Record {
		public let dependent: DependentValue
		public let value: Value

		public init(dependent: DependentValue, value: Value) {
			self.dependent = dependent
			self.value = value
		}
	}

	public struct KeyedRecord {
		public let key: Key
		public let dependent: DependentValue
		public let value: Value

		public init(key: Key, dependent: DependentValue, value: Value) {
			self.key = key
			self.dependent = dependent
			self.value = value
		}

		public var unkeyedRecord: Record {
			Record(dependent: dependent, value: value)
		}
	}
}

extension DPlusTree.Record: Equatable where DependentValue: Equatable, Value: Equatable {}

extension DPlusTree {
	public struct Configuration {
		public let order: Int
		public let combineDependents: CombineDependents
		public let keyFromDependent: KeyFromDependent
		public let initial: DependentValue

		public init(
			order: Int = 5,
			initial: DependentValue,
			combineDependents: @escaping CombineDependents,
			keyFromDependent: @escaping KeyFromDependent
		) {
			self.order = order
			self.initial = initial
			self.combineDependents = combineDependents
			self.keyFromDependent = keyFromDependent
		}
	}

	func resolve(_ record: KeyedRecord, with value: DependentValue) -> KeyedRecord {
		let merged = configuration.combineDependents(value, record.dependent)

		return KeyedRecord(key: record.key, dependent: merged, value: record.value)
	}
}

extension DPlusTree {
	public subscript(key: Key) -> Record? {
		get {
			let comp = configuration.keyFromDependent

			return lookup(by: key, using: { comp($0) })
		}
		set {
//			if let newValue {
//				insert(newValue, for: key)
//			} else {
//				delete(key)
//			}
		}
	}

	/// Search the tree using a custom comparator function.
	///
	/// > Warning: You must respect the invariant: `block(a) < block(b) => a.key < b.key`.
	public func lookup<T: Comparable>(by value: T, using block: Query<T>) -> Record? {
		return nil
	}
}

extension DPlusTree {
	struct Leaf {
		var records: [Record]
		var next: Node?
	}

	struct Internal {
		var children: [Node]
		var keys: [KeyedRecord]
		var hasLeaves: Bool
	}

	enum Kind {
		case internalNode(Internal)
		case leaf(Leaf)
	}

	final class Node {
		var kind = Kind.leaf(Leaf(records: [], next: nil))
	}
}

extension DPlusTree {
	public func insert<T: Comparable>(_ record: Record, for target: T, using query: Query<T>) {
		let initial = configuration.initial
		let key = configuration.keyFromDependent(initial)

		let (node, parent) = findLeaf(in: root, parentValue: initial, with: target, using: query)

		print("node, parent: ", node, parent)
	}

	public func insert(_ record: Record, for key: Key) {
		insert(record, for: key, using: configuration.keyFromDependent)
	}

	public func insert(_ keyedRecord: KeyedRecord) {
		insert(keyedRecord.unkeyedRecord, for: keyedRecord.key)
	}

	func delete(_ key: Key) {

	}

	func findLeaf<T: Comparable>(in node: Node, parentValue: DependentValue, with target: T, using query: Query<T>) -> (Node, Node?) {
		let key = configuration.keyFromDependent(parentValue)

		switch node.kind {
		case let .leaf(leaf):
			let idx = leaf.records.binarySearch { record in
				let merged = configuration.combineDependents(record.dependent, parentValue)
				let value = query(merged)

				return value < target
			}

			print("idx: ", idx)
		case let .internalNode(internalNode):
			print("internal: ", internalNode)
		}

		return (node, nil)
	}
}
