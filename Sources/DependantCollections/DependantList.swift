import DependantCollectionsInternal

public final class DependantList<Value, Weight> where Weight : Comparable {
	public typealias WeightedValue = DependantArray<Value, Weight>.WeightedValue
	public typealias Record = DependantArray<Value, Weight>.Record
	public typealias Predicate = (Weight, Index) -> Bool
	public typealias WeightOperator = (Weight, Weight) -> Weight

	typealias LeafStorage = DependantArray<Value, Weight>

	struct Position {
		let node: Node
		let index: LeafStorage.Index
	}

	private var root: Node
	let configuration: Configuration

	public init(configuration: Configuration) {
		self.configuration = configuration
		self.root = Node(kind: .leaf(Leaf(configuration: configuration.leafConfiguration)))
	}
}

extension DependantList {
	public struct Capacity {
		public let intern: Int
		public let leaf: Int

		public init(leaf: Int = 100, intern: Int = 100) {
			self.leaf = leaf
			self.intern = intern
		}
	}

	public struct Configuration {
		public let capacity: Capacity
		let leafConfiguration: LeafStorage.Configuration

		public init(
			capacity: Capacity = .init(),
			initial: Weight,
			add: @escaping WeightOperator,
			subtract: @escaping WeightOperator
		) {
			self.capacity = capacity
			self.leafConfiguration = .init(initial: initial, add: add, subtract: subtract)
		}

		public var initial: Weight {
			leafConfiguration.initial
		}
	}
}

extension DependantList.Configuration where Weight : AdditiveArithmetic {
	public init(capacity: DependantList.Capacity = .init()) {
		self.capacity = capacity
		self.leafConfiguration = .init()
	}
}

extension DependantList where Weight : AdditiveArithmetic {
	public convenience init() {
		self.init(configuration: .init())
	}
}

extension DependantList {
	struct Leaf {
		var records: LeafStorage
		var next: Node?

		init(configuration: LeafStorage.Configuration) {
			self.records = LeafStorage(configuration: configuration)
			self.next = nil
		}

		init(existing: Slice<LeafStorage>, splitFrom leaf: Leaf) {
			self.records = LeafStorage(existing)
			self.next = leaf.next
		}

		var count: Int {
			records.count
		}

		var weight: Weight {
			records.first?.weight ?? records.configuration.initial
		}

		mutating func split(with capacity: Int) -> Node {
			// split up the records
			let startIndex = records.startIndex
			let splitIndex = records.index(records.startIndex, offsetBy: capacity)

			let leftRecords = records[startIndex..<splitIndex]
			let rightRecords = records[splitIndex..<records.endIndex]

			precondition(leftRecords.isEmpty == false)
			precondition(rightRecords.isEmpty == false)

			// create the new (right) node
			let newLeaf = Leaf(existing: rightRecords, splitFrom: self)
			let newNode = Node(newLeaf)

			// update the left node
			records = LeafStorage(leftRecords)
			next = newNode

			return newNode
		}
	}

	struct Internal {
		var weight: Weight
		var recordCount: Int
		var nodes: ContiguousArray<Node>

		init(weight: Weight) {
			self.weight = weight
			self.recordCount = 0
			self.nodes = ContiguousArray()
		}
	}

	final class Node {
		enum Kind {
			case intern(Internal)
			case leaf(Leaf)
		}

		var kind: Kind
		var indexOffset: Index

		init(kind: Kind) {
			self.kind = kind
			self.indexOffset = 0
		}

		init(_ leaf: Leaf) {
			self.kind = .leaf(leaf)
			self.indexOffset = 0
		}

		var count: Int {
			switch self.kind {
			case let .leaf(leaf):
				leaf.records.count
			case let .intern(intern):
				intern.nodes.count
			}
		}

		var isEmpty: Bool {
			switch kind {
			case let .leaf(leaf):
				leaf.records.isEmpty
			case let .intern(intern):
				intern.nodes.isEmpty
			}
		}

		var weight: Weight {
			return switch kind {
			case let .leaf(leaf):
				leaf.weight
			case let .intern(intern):
				intern.weight
			}
		}

		var recordCount: Int {
			switch self.kind {
			case let .intern(intern):
				intern.recordCount
			case let .leaf(leaf):
				leaf.count
			}
		}

		func split(with capacity: Capacity) -> Node {
			switch self.kind {
			case var .leaf(leaf):
				let newNode = leaf.split(with: capacity.leaf)

				self.kind = .leaf(leaf)

				newNode.indexOffset = indexOffset + leaf.count

				return newNode
			case .intern:
				fatalError()
			}
		}

		func index(satisifying predicate: Predicate) -> Index? {
			switch kind {
			case let .leaf(leaf):
				return leaf.records.binarySearch(predicate: { predicate($0.weight, $1) })
			case let .intern(intern):
				return intern.nodes.binarySearch(predicate: { predicate($0.weight, $1) })
			}
		}
	}
}

extension DependantList {
	public func append(_ value: WeightedValue) {
		insert(value, at: endIndex)
	}

	private func insert(_ value: WeightedValue, at index: Index) {
		recursiveInsert(value, in: root, parent: nil, using: { $1 >= index })

		recursivePrint(root)
	}

	private func recursiveInsert(_ weighted: WeightedValue, in node: Node, parent: Node?, using predicate: Predicate) {
		let offset = node.indexOffset

		let idx = node.index(satisifying: predicate)

		switch node.kind {
		case var .leaf(leaf):
			let idx = leaf.records.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
			let target = idx ?? leaf.records.endIndex

			leaf.records.insert(weighted, at: target)

			node.kind = .leaf(leaf)

			if leaf.count > configuration.capacity.leaf {
				let newNode = node.split(with: configuration.capacity)

				addChild(newNode, to: parent, using: predicate)
			}
		case var .intern(intern):
			let idx = intern.nodes.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
			guard let target = idx ?? intern.nodes.lastIndex else {
				preconditionFailure("Unable to find index within internal node, is it empty?")
			}

			recursiveInsert(weighted, in: intern.nodes[target], parent: node, using: predicate)

			intern.recordCount += 1

			node.kind = .intern(intern)
		}
	}

	private func findPosition(in node: Node, using predicate: Predicate) -> Position {
		let offset = node.indexOffset

		switch node.kind {
		case let .leaf(leaf):
			let idx = leaf.records.binarySearch(predicate: { predicate($0.weight, $1 + offset) })

			return Position(node: node, index: idx ?? leaf.records.endIndex)
		case .intern:
			fatalError()
		}
	}

	private func findPosition(in _: Node, at index: Index) -> Position {
		var pos: Position = Position(node: root, index: 0)

		let pred: Predicate = { _, idx in
			return idx >= index
		}
		
		recursiveFind(in: root, parent: nil, using: pred) { node, idx, parent in
			pos = Position(node: node, index: idx)
		}

		return pos
	}

	public func replace(_ weighted: WeightedValue, at index: Index) {
//		let position = findPosition(in: root, at: index)
//
//		guard case var .leaf(leaf) = position.node.kind else { preconditionFailure() }
//
//		leaf.records.replace(weighted, at: position.index)
//
//		position.node.kind = .leaf(leaf)
	}

	public func remove(at index: Index) {
//		let position = findPosition(in: root, at: index)
//
//		guard case var .leaf(leaf) = position.node.kind else { preconditionFailure() }
//
//		leaf.records.remove(at: position.index)
//
//		position.node.kind = .leaf(leaf)
	}
}

extension DependantList {
	private func addChild(_ newNode: Node, to parent: Node?, using predicate: Predicate) {
		precondition(newNode !== parent)

		switch parent?.kind {
		case .leaf:
			preconditionFailure()
		case nil:
			var intern = Internal(weight: configuration.initial)

			intern.nodes = [root, newNode]
			intern.recordCount = newNode.recordCount + root.recordCount

			self.root = Node(kind: .intern(intern))

		case var .intern(intern):
			let idx = intern.nodes.binarySearch(predicate: { predicate($0.weight, $1) })
			let target = idx ?? intern.nodes.endIndex

			intern.nodes.insert(newNode, at: target)
		}
	}

	private func recursiveFind(in node: Node, parent: Node?, using predicate: Predicate, block: (Node, Index, Node?) -> Void) {
		let offset = node.indexOffset

		switch node.kind {
		case let .leaf(leaf):
			let idx = leaf.records.binarySearch(predicate: { predicate($0.weight, $1 + offset) })

			let target = idx ?? leaf.records.endIndex

			block(node, target, parent)
		case let .intern(intern):
			let idx = intern.nodes.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
			guard let target = idx ?? intern.nodes.lastIndex else {
				preconditionFailure("Unable to find index within internal node, is it empty?")
			}

			recursiveFind(in: intern.nodes[target], parent: node, using: predicate, block: block)
		}
	}
	private func recursivePrint(_ node: Node, depth: Int = 0) {
		let padding = String(repeating: "\t", count: depth)

		let offset = node.indexOffset
		let recordCount = node.recordCount
		let weight = node.weight

		switch node.kind {
		case let .intern(intern):
			print("\(padding)Intern: \(offset), \(weight), \(recordCount)")

			for subNode in intern.nodes {
				recursivePrint(subNode, depth: depth + 1)
			}
		case let .leaf(leaf):
			let content = leaf.records.map({ $0.debugDescription }).joined(separator: ", ")

			print("\(padding)Leaf: \(offset), \(weight) [\(content)]")
		}
	}
}

extension DependantList : Sequence {
	public struct Iterator : IteratorProtocol {
		private var node: Node?
		private var index: Array.Index

		init(node: Node) {
			self.node = node

			guard case let .leaf(leaf) = node.kind else { preconditionFailure() }

			self.index = leaf.records.startIndex
		}

		public mutating func next() -> Record? {
			guard let currentNode = node else { return nil }
			guard case let .leaf(leaf) = currentNode.kind else { preconditionFailure() }

			if index == leaf.records.endIndex {
				return nil
			}

			let value = leaf.records[index]

			index = leaf.records.index(after: index)
			if index >= leaf.records.endIndex {
				node = leaf.next
			}

			return value
		}
	}

	public func makeIterator() -> Iterator {
		Iterator(node: root)
	}
}


extension DependantList : RandomAccessCollection {
	public typealias Index = Int

	public var startIndex: Index {
		0
	}

	public var endIndex: Index {
		root.recordCount
	}

	public func index(after i: Index) -> Index {
		i + 1
	}

	public subscript(position: Index) -> Record {
		_read {
			let pos = findPosition(in: root, at: position)

			guard case let .leaf(leaf) = pos.node.kind else { preconditionFailure() }

			yield leaf.records[pos.index]
		}
	}
}

