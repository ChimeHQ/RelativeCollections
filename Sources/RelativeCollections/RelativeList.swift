import RelativeCollectionsInternal

public final class RelativeList<Value, Weight> where Weight : Comparable {
	public typealias WeightedValue = RelativeArray<Value, Weight>.WeightedValue
	public typealias Record = RelativeArray<Value, Weight>.Record
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

extension RelativeList {
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

extension RelativeList.Configuration where Weight : AdditiveArithmetic {
	public init(capacity: RelativeList.Capacity = .init()) {
		self.capacity = capacity
		self.leafConfiguration = .init()
	}
}

extension RelativeList where Weight : AdditiveArithmetic {
	public convenience init() {
		self.init(configuration: .init())
	}
}

extension RelativeList {
	/// Insert a new WeightedValue
	///
	/// This will recursively descend down the tree to find the insertion point. It will then also recursively split nodes as needed to maintain the tree balance.
	private func insert(_ weighted: WeightedValue, at target: Index, in node: Node, parent: Node?) {
		switch node.kind {
 		case var .leaf(leaf):
			leaf.storage.insert(weighted, at: target)

			node.kind = .leaf(leaf)
		case var .branch(branch):
			guard let entryIndex = branch.localIndex(representing: target) else {
				fatalError()
			}

			var branchEntry = branch.storage[entryIndex]
			let subNode = branchEntry.value
			let adjustedTarget = target - branchEntry.dependency.count

			// before we recurse, update the values tracked by this branch entry
			branch.count += 1

			let addedWeight = Branch.NodeWeight(count: 1, weight: weighted.weight)

			branchEntry.weightedValue.weight = branch.storage.configuration.add(branchEntry.weightedValue.weight, addedWeight)
			branch.storage.replace(branchEntry.weightedValue, at: entryIndex)

			// now recurse
			insert(weighted, at: adjustedTarget, in: subNode, parent: node)

			if subNode.isTooFull(for: configuration.capacity) {
				// subnode is now holding too much, gotta split it
				let newWeightedValue = subNode.split()

				// and on return, we will recursively re-check this value for a needed split
				branch.storage.insert(newWeightedValue, at: entryIndex)
			}

			node.kind = .branch(branch)
		}

		// check if the root needs splitting too
		if node === root && node.isTooFull(for: configuration.capacity) {
			precondition(parent == nil)

			splitRoot()
		}
	}

	private func replace(_ weighted: WeightedValue, at target: Index, in node: Node) {
		switch node.kind {
		case var .leaf(leaf):
			leaf.storage.replace(weighted, at: target)

			node.kind = .leaf(leaf)
		case var .branch(branch):
			guard let entryIndex = branch.localIndex(representing: target) else {
				fatalError()
			}

			var branchEntry = branch.storage[entryIndex]
			let subNode = branchEntry.value
			let adjustedTarget = target - branchEntry.dependency.count

			let currentWeight = branchEntry.weightedValue.weight
			let newWeight = Branch.NodeWeight(count: 0, weight: weighted.weight)

			branchEntry.weightedValue.weight = branch.storage.configuration.subtract(currentWeight, newWeight)
			branch.storage.replace(branchEntry.weightedValue, at: entryIndex)

			// now recurse
			replace(weighted, at: adjustedTarget, in: subNode)

			node.kind = .branch(branch)
		}
	}

	private func remove(at target: Index, in node: Node) {
		switch node.kind {
		case var .leaf(leaf):
			leaf.storage.remove(at: target)

			node.kind = .leaf(leaf)
		case var .branch(branch):
			guard let entryIndex = branch.localIndex(representing: target) else {
				fatalError()
			}

			var branchEntry = branch.storage[entryIndex]
			let subNode = branchEntry.value
			let adjustedTarget = target - branchEntry.dependency.count

			// before we recurse, update the values tracked by this branch entry
			branch.count -= 1

			// now recurse
			remove(at: adjustedTarget, in: subNode)

			node.kind = .branch(branch)
		}
	}
}

extension RelativeList {
	private func recursivePrint() {
		print("internal rep:")
		root.recursivePrint(depth: 0, nodeWeight: .init(count: 0, weight: configuration.initial))
	}

	private func splitRoot() {
		let newWeightedValue = root.split()

		var branch = RelativeList.Branch(configuration: configuration.leafConfiguration)

		let weight = root.weight ?? configuration.initial
		let rootNodeWeight = Branch.NodeWeight(count: root.count, weight: weight)

		branch.storage.append(.init(value: root, weight: rootNodeWeight))
		branch.storage.append(newWeightedValue)
		branch.count = branch.storage.reduce(0, { $0 + $1.weightedValue.weight.count })

		self.root = Node(kind: .branch(branch))
	}
}

extension RelativeList {
	public func append(_ value: WeightedValue) {
		insert(value, at: endIndex)
	}

	public func insert(_ value: WeightedValue, at index: Index) {
		insert(value, at: index, in: root, parent: nil)

		recursivePrint()
	}

	public func replace(_ weighted: WeightedValue, at index: Index) {
		replace(weighted, at: index, in: root)
	}

	public func remove(at index: Index) {
		remove(at: index, in: root)
	}
}

extension RelativeList {
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

extension RelativeList : Sequence {
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


extension RelativeList : RandomAccessCollection {
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
