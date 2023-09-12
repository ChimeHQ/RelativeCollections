///// A B+Tree that supports order-relative keys.
/////
///// `Key` must have a primary sort order, enfored by its `Comparable` conformance.
/////
/////	Data(0) = Value(0)
/////	Data(1) = Value(1), Key(0)
/////	Data(2) = Value(2), Key(0) + Key(1)
///// Data(N) = Value(N), Sum(Key(0) ... Key(N-1))
//public final class DPlusTree<Key: Comparable, DependentValue, Value> {
//	/// Add two keys
//	///
//	/// Invariant: Result > A && Result > B
//	public typealias AddKeys = (Key, Key) -> Key
//
//	/// Subtract two keys
//	///
//	/// Invariant: Result <= A && Result <= B
//
//	public typealias SubtractKeys = (Key, Key) -> Key
//
//	/// Compare keys by an arbitrary, order-preserving property
//	///
//	/// Invariant: Result == A < B
//	public typealias SearchComparator = (Key, Key) -> Bool
//
//	public typealias CombineDependents = (_ lhs: DependentValue, _ rhs: DependentValue) -> DependentValue
//	public typealias KeyFromDependent = (_ dependent: DependentValue) -> Key
//	public typealias Query<T: Comparable> = (DependentValue) -> T
//
//	let configuration: Configuration
//
//	private var root: Node
//
//	public init(configuration: Configuration) {
//		self.configuration = configuration
//		self.root = Node()
//	}
//}
//
//extension DPlusTree {
//	public struct Record {
//		public internal(set) var dependent: DependentValue
//		public let value: Value
//
//		public init(dependent: DependentValue, value: Value) {
//			self.dependent = dependent
//			self.value = value
//		}
//	}
//
//	public struct KeyedRecord {
//		public let key: Key
//		public let dependent: DependentValue
//		public let value: Value
//
//		public init(key: Key, dependent: DependentValue, value: Value) {
//			self.key = key
//			self.dependent = dependent
//			self.value = value
//		}
//
//		public var unkeyedRecord: Record {
//			Record(dependent: dependent, value: value)
//		}
//	}
//}
//
//extension DPlusTree.Record: Equatable where DependentValue: Equatable, Value: Equatable {}
//
//extension DPlusTree.Record: CustomDebugStringConvertible {
//	public var debugDescription: String {
//		"<Record: \(dependent), \(value)>"
//	}
//}
//
//extension DPlusTree {
//	public struct ResolutionContext {
//		var previous: DependentValue
//		let combineDependents: CombineDependents
//
//		func resolve(_ record: Record) -> Record {
//			let resolvedDep = combineDependents(previous, record.dependent)
//
//			return Record(dependent: resolvedDep, value: record.value)
//		}
//
//		mutating func resolveAssign(_ record: Record) -> Record {
//			let newRecord = resolve(record)
//
//			self.previous = newRecord.dependent
//
//			return newRecord
//		}
//	}
//
//	public struct Configuration {
//		public let order: Int
//		public let combineDependents: CombineDependents
//		public let keyFromDependent: KeyFromDependent
//		public let initial: DependentValue
//
//		public init(
//			order: Int = 5,
//			initial: DependentValue,
//			combineDependents: @escaping CombineDependents,
//			keyFromDependent: @escaping KeyFromDependent
//		) {
//			self.order = order
//			self.initial = initial
//			self.combineDependents = combineDependents
//			self.keyFromDependent = keyFromDependent
//		}
//	}
//
//	func resolve(_ record: KeyedRecord, with value: DependentValue) -> KeyedRecord {
//		let merged = configuration.combineDependents(value, record.dependent)
//
//		return KeyedRecord(key: record.key, dependent: merged, value: record.value)
//	}
//}
//
//extension DPlusTree {
//	public subscript(key: Key) -> Record? {
//		get {
//			let comp = configuration.keyFromDependent
//
//			return lookup(by: key, using: { comp($0) })
//		}
//		set {
////			if let newValue {
////				insert(newValue, for: key)
////			} else {
////				delete(key)
////			}
//		}
//	}
//
//	/// Search the tree using a custom comparator function.
//	///
//	/// > Warning: You must respect the invariant: `block(a) < block(b) => a.key < b.key`.
//	public func lookup<T: Comparable>(by value: T, using block: Query<T>) -> Record? {
//		return nil
//	}
//}
//
//extension DPlusTree {
//	struct Leaf {
//		var records: [Record]
//		var next: Node?
//
//		var count: Int {
//			records.count
//		}
//
//		mutating func insert<T: Comparable>(_ record: Record, for target: T, using query: Query<T>) {
//
//		}
//
//		func resolveRecord(at index: Int, with context: ResolutionContext) -> Record {
//			let record = records[index]
//
//			if index == 0 {
//				return context.resolve(record)
//			}
//
//			let previousRecord = records[index - 1]
//			let previousResolved = context.resolve(previousRecord)
//			let newDependent = context.combineDependents(previousResolved.dependent, record.dependent)
//
//			return Record(dependent: newDependent, value: record.value)
//		}
//
//		func index<T: Comparable>(of target: T, using query: Query<T>, with context: ResolutionContext) -> Int? {
//			records.binarySearch { record, i in
//				let resolved = resolveRecord(at: i, with: context)
//				let value = query(resolved.dependent)
//
//				return value < target
//			}
//		}
//	}
//
//	struct Internal {
//		var children: [Node]
//		var keys: [KeyedRecord]
//		var hasLeaves: Bool
//		var dependentValue: DependentValue
//	}
//
//	enum Kind {
//		case internalNode(Internal)
//		case leaf(Leaf)
//	}
//
//	final class Node {
//		var kind = Kind.leaf(Leaf(records: [], next: nil))
//
//		var dependentValue: DependentValue? {
//			switch kind {
//			case let .internalNode(value):
//				return value.dependentValue
//			case .leaf:
//				return nil
//			}
//		}
//	}
//}
//
//extension DPlusTree {
//	public func insert<T: Comparable>(_ record: Record, for target: T, using query: Query<T>) {
//		let (node, index, parent) = findLeaf(in: root, parent: nil, with: target, using: query)
//
//		guard case var .leaf(leaf) = node.kind else {
//			preconditionFailure("located node must be a leaf")
//		}
//
//		leaf.records.insert(record, at: index)
//		
//		// update dependent information
//		let nextIdx = leaf.records.index(after: index)
//		if nextIdx < leaf.records.endIndex {
//			leaf.records[nextIdx].dependent = record.dependent
//		}
//
//		print(leaf.records)
//		
//		node.kind = .leaf(leaf)
//		// possibly split
//
//
//	}
//
//	public func insert(_ record: Record, for key: Key) {
//		insert(record, for: key, using: configuration.keyFromDependent)
//	}
//
//	public func insert(_ keyedRecord: KeyedRecord) {
//		insert(keyedRecord.unkeyedRecord, for: keyedRecord.key)
//	}
//
//	func delete(_ key: Key) {
//
//	}
//
//	func findLeaf<T: Comparable>(in node: Node, parent: Node?, with target: T, using query: Query<T>) -> (Node, Int, Node?) {
//		let parentValue = parent?.dependentValue ?? configuration.initial
//		let key = configuration.keyFromDependent(parentValue)
//		let context = ResolutionContext(previous: parentValue, combineDependents: configuration.combineDependents)
//
//		switch node.kind {
//		case let .leaf(leaf):
//			let idx = leaf.index(of: target, using: query, with: context)
//
//			return (node, idx ?? leaf.records.endIndex, parent)
//		case let .internalNode(internalNode):
//			print("internal: ", internalNode)
//
//			fatalError()
//		}
//	}
//}
