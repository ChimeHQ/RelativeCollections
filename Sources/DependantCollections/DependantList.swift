import DependantCollectionsInternal

public final class DependantList<Value, Weight> where Weight : Comparable {
	public typealias WeightedValue = DependantArray<Value, Weight>.WeightedValue
	public typealias Record = DependantArray<Value, Weight>.Record
	public typealias Predicate = (Weight, Index) -> Bool
	public typealias WeightOperator = (Weight, Weight) -> Weight

	struct Position {
		let node: Node
		let index: Index
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
		public let branch: Int
		public let leaf: Int

		public init(leaf: Int = 100, branch: Int = 100) {
			self.leaf = leaf
			self.branch = branch
		}
	}

	public struct Configuration {
		public let capacity: Capacity
		let leafConfiguration: Leaf.Storage.Configuration

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
	/// Insert a new WeightedValue
	///
	/// This will recursively decend down the tree to find the insertion point. It will then also recursively split nodes as needed to maintain the tree balance.
	func insert(_ weighted: WeightedValue, at target: Index, in node: Node, parent: Node?) {
		switch node.kind {
 		case var .leaf(leaf):
			leaf.storage.insert(weighted, at: target)

			node.kind = .leaf(leaf)
		case var .branch(branch):
			guard let entryIndex = branch.localIndex(representing: target) else {
				preconditionFailure("Index isn't in this node")
			}

			let branchEntry = branch.storage[entryIndex]
			let subNode = branchEntry.value
			let adjustedTarget = target - branchEntry.dependency.count
			let adjustedWeight = configuration.leafConfiguration.subtract(weighted.weight, branchEntry.weight.weight)
			let adjustedWeighted = DependantList.WeightedValue(value: weighted.value, weight: adjustedWeight)

			insert(adjustedWeighted, at: adjustedTarget, in: subNode, parent: node)

			guard subNode.exceeds(configuration.capacity) == false else { return }

			// subnode is now holding too much, gotta split it
			let newWeightedValue = subNode.split()

			// and on return, we will recursively re-check this value for a needed split
			branch.storage.insert(newWeightedValue, at: entryIndex)

			node.kind = .branch(branch)
		}

		// check if the root needs splitting too
		if node === root && node.exceeds(configuration.capacity) {
			precondition(parent == nil)

			splitRoot()
		}
	}
}

extension DependantList {
	private func splitRoot() {
		let newWeightedValue = root.split()

		var branch = DependantList.Branch(configuration: configuration.leafConfiguration)

		let weight = root.weight ?? configuration.initial
		let rootNodeWeight = Branch.NodeWeight(count: root.count, weight: weight)

		branch.storage.append(.init(value: root, weight: rootNodeWeight))
		branch.storage.append(newWeightedValue)

		self.root = Node(kind: .branch(branch))
	}
}

extension DependantList {
	public func append(_ value: WeightedValue) {
		insert(value, at: endIndex)
	}

	public func insert(_ value: WeightedValue, at index: Index) {
		insert(value, at: index, in: root, parent: nil)

		print("internal rep:")
		root.recursivePrint(depth: 0, nodeWeight: .init(count: 0, weight: configuration.initial))
	}

//	private func recursiveInsert(_ weighted: WeightedValue, in node: NewNode, parent: NewNode?, using predicate: Predicate) {
//		let offset = node.indexOffset
//
//		let idx = node.index(satisifying: predicate)
//
//		switch node.kind {
//		case var .leaf(leaf):
//			let idx = leaf.records.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
//			let target = idx ?? leaf.records.endIndex
//
//			leaf.records.insert(weighted, at: target)
//
//			node.kind = .leaf(leaf)
//
//			if leaf.count > configuration.capacity.leaf {
//				let newNode = node.split(with: configuration.capacity)
//
//				addChild(newNode, to: parent, using: predicate)
//			}
//		case var .intern(intern):
//			let idx = intern.nodes.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
//			guard let target = idx ?? intern.nodes.lastIndex else {
//				preconditionFailure("Unable to find index within internal node, is it empty?")
//			}
//
//			recursiveInsert(weighted, in: intern.nodes[target], parent: node, using: predicate)
//
//			intern.recordCount += 1
//
//			node.kind = .intern(intern)
//		}
//	}
//
//	private func findPosition(in node: Node, using predicate: Predicate) -> Position {
//		let offset = node.indexOffset
//
//		switch node.kind {
//		case let .leaf(leaf):
//			let idx = leaf.records.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
//
//			return Position(node: node, index: idx ?? leaf.records.endIndex)
//		case .intern:
//			fatalError()
//		}
//	}
//
//	private func findPosition(in _: Node, at index: Index) -> Position {
//		var pos: Position = Position(node: root, index: 0)
//
//		let pred: Predicate = { _, idx in
//			return idx >= index
//		}
//		
//		recursiveFind(in: root, parent: nil, using: pred) { node, idx, parent in
//			pos = Position(node: node, index: idx)
//		}
//
//		return pos
//	}

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
//	private func addChild(_ newNode: Node, to parent: Node?, using predicate: Predicate) {
//		precondition(newNode !== parent)
//
//		switch parent?.kind {
//		case .leaf:
//			preconditionFailure()
//		case nil:
//			var intern = Internal(weight: configuration.initial)
//
//			intern.nodes = [root, newNode]
//			intern.recordCount = newNode.recordCount + root.recordCount
//
//			self.root = Node(kind: .intern(intern))
//
//		case var .intern(intern):
//			let idx = intern.nodes.binarySearch(predicate: { predicate($0.weight, $1) })
//			let target = idx ?? intern.nodes.endIndex
//
//			intern.nodes.insert(newNode, at: target)
//		}
//	}

//	private func recursiveFind(in node: Node, parent: Node?, using predicate: Predicate, block: (Node, Index, Node?) -> Void) {
//		let offset = node.indexOffset
//
//		switch node.kind {
//		case let .leaf(leaf):
//			let idx = leaf.records.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
//
//			let target = idx ?? leaf.records.endIndex
//
//			block(node, target, parent)
//		case let .intern(intern):
//			let idx = intern.nodes.binarySearch(predicate: { predicate($0.weight, $1 + offset) })
//			guard let target = idx ?? intern.nodes.lastIndex else {
//				preconditionFailure("Unable to find index within internal node, is it empty?")
//			}
//
//			recursiveFind(in: intern.nodes[target], parent: node, using: predicate, block: block)
//		}
//	}
}

extension DependantList : Sequence {
	public struct Iterator : IteratorProtocol {
		private var node: Node?
		private var index: Array.Index

		init(node: Node) {
			self.node = node

			guard case let .leaf(leaf) = node.kind else { preconditionFailure() }

			self.index = leaf.storage.startIndex
		}

		public mutating func next() -> Record? {
			guard let currentNode = node else { return nil }
			guard case let .leaf(leaf) = currentNode.kind else { preconditionFailure() }

			if index == leaf.storage.endIndex {
				return nil
			}

			let value = leaf.storage[index]

			index = leaf.storage.index(after: index)
			if index >= leaf.storage.endIndex {
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
		root.count
	}

	public func index(after i: Index) -> Index {
		i + 1
	}

	public subscript(position: Index) -> Record {
		_read {
			yield root.record(at: position)
		}
	}
}
