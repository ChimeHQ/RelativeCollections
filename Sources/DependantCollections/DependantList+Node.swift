extension DependantList {
	struct Leaf {
		typealias Storage = DependantArray<Value, Weight>

		var storage: Storage
		var next: Node?

		init(configuration: Storage.Configuration) {
			self.storage = Storage(configuration: configuration)
			self.next = nil
		}

		init(storage: Storage, next: Node?) {
			self.storage = storage
			self.next = next
		}

		var nextLeaf: Leaf? {
			guard let next = next else { return nil }

			guard case let .leaf(leaf) = next.kind else {
				preconditionFailure("Leaf next does not point to a leaf node")
			}

			return leaf
		}

		mutating func split() -> Branch.Storage.WeightedValue {
			let (left, right) = storage.halve()

			precondition(left.isEmpty == false)
			precondition(right.isEmpty == false)

			// update the left node
			self.storage = Storage(left)

			// create the new (right) node, and deal with the weights
			var newStorage = Storage(right)
			let startWeight = newStorage.extractInitialDependency()
			let nodeWeight = Branch.NodeWeight(count: right.count, weight: startWeight)
			let newLeaf = Leaf(storage: newStorage, next: next)

			let newNode = Node(kind: .leaf(newLeaf))

			self.next = newNode

			return .init(value: newNode, weight: nodeWeight)
		}
	}
}

extension DependantList {
	struct Branch {
		typealias Storage = DependantArray<Node, NodeWeight>

		struct NodeWeight : Comparable {
			let count: Int
			let weight: Weight

			static func < (lhs: Self, rhs: Self) -> Bool {
				lhs.weight < rhs.weight
			}
		}

		var storage: Storage

		init(configuration: DependantList.Leaf.Storage.Configuration) {
			let config = Storage.Configuration(
				initial: NodeWeight(count: 0, weight: configuration.initial),
				add: { NodeWeight(count: $0.count + $1.count, weight: configuration.add($0.weight, $0.weight)) },
				subtract: { NodeWeight(count: $0.count - $1.count, weight: configuration.subtract($0.weight, $0.weight)) }
			)

			self.storage = Storage(configuration: config)
		}

		init(storage: Storage) {
			self.storage = storage
		}

		/// Returns the local branch record index for the node holding a more deeply-nested index.
		///
		/// We can avoid reconstructing the full `NodeWeight` object here, because we only need to consider total counts.
		func localIndex(representing target: Index) -> Index? {
			storage.binarySearch { branchEntry, storageIndex in
				let totalCount = branchEntry.dependency.count + branchEntry.weight.count

				return target <= totalCount
			}
		}

		mutating func split() -> Storage.WeightedValue {
			let (left, right) = storage.halve()

			precondition(left.isEmpty == false)
			precondition(right.isEmpty == false)

			// update the left node
			self.storage = Storage(left)

			// create the new (right) node, and deal with the weights
			var newStorage = Storage(right)
//			let startWeight = newStorage.extractInitialDependency()
			let nodeWeight = Branch.NodeWeight(count: right.count, weight: newStorage[0].weight.weight)
			let newBranch = Branch(storage: newStorage)

			let newNode = Node(kind: .branch(newBranch))

			return .init(value: newNode, weight: nodeWeight)
		}
	}
}

extension DependantList {
	final class Node {
		enum Kind {
			case branch(Branch)
			case leaf(Leaf)
		}

		var kind: Kind

		init(kind: Kind) {
			self.kind = kind
		}

		var count: Int {
			switch kind {
			case let .leaf(leaf):
				leaf.storage.count
			case let .branch(branch):
//				branch.count
                0
			}
		}

		var lastElementWeight: Weight? {
			switch kind {
			case let .leaf(leaf):
				leaf.storage.last?.weight
			case let .branch(branch):
				branch.storage.last?.weight.weight
			}
		}

		func exceeds(_ capacity: Capacity) -> Bool {
			switch kind {
			case let .leaf(leaf):
				leaf.storage.count > capacity.leaf
			case let .branch(branch):
				branch.storage.count > capacity.branch
			}
		}

		func split() -> Branch.Storage.WeightedValue {
			// this is bad. could all of this splitting be generalized? It's so similar...
			switch kind {
			case var .leaf(leaf):
				let value = leaf.split()

				self.kind = .leaf(leaf)

				return value
			case var .branch(branch):
				let value = branch.split()

				self.kind = .branch(branch)

				return value
			}
		}
	}
}

extension DependantList.Node {
	func record(at target: DependantList.Index) -> DependantList.Record {
		switch kind {
		case let .leaf(leaf):
			precondition(target >= 0)
			precondition(target < leaf.storage.count)
			
			return leaf.storage[target]
		case let .branch(branch):
			guard let entryIndex = branch.localIndex(representing: target) else {
				preconditionFailure("Index isn't in this node")
			}

			let branchEntry = branch.storage[entryIndex]
			let node = branchEntry.value
			let adjustedTarget = target - branchEntry.dependency.count

			return node.record(at: adjustedTarget)
		}
	}
}

extension DependantList.Node {
	func recursivePrint(depth: Int = 0, nodeWeight: DependantList.Branch.NodeWeight) {
		let padding = String(repeating: "\t", count: depth)
		let offset = nodeWeight.count
		let weight = nodeWeight.weight

		switch kind {
		case let .branch(branch):
			print("\(padding)Branch: \(offset), \(weight), \(count)")

			for record in branch.storage {
				record.value.recursivePrint(depth: depth + 1, nodeWeight: record.dependency)
			}
		case let .leaf(leaf):
			let content = leaf.storage
				.map({ $0.debugDescription })
				.joined(separator: ", ")

			print("\(padding)Leaf: \(offset), \(weight) [\(content)]")
		}
	}
}
