extension RelativeList {
	struct Leaf {
		typealias Storage = RelativeArray<Value, Weight>

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

extension RelativeList {
	struct Branch {
		typealias Storage = RelativeArray<Node, NodeWeight>

		struct NodeWeight : Comparable {
			let count: Int
			let weight: Weight

			static func < (lhs: Self, rhs: Self) -> Bool {
				lhs.weight < rhs.weight
			}
		}

		var storage: Storage
		var count: Int

		init(configuration: RelativeList.Leaf.Storage.Configuration) {
			let config = Storage.Configuration(
				initial: NodeWeight(count: 0, weight: configuration.initial),
				add: { NodeWeight(count: $0.count + $1.count, weight: configuration.add($0.weight, $1.weight)) },
				subtract: { NodeWeight(count: $0.count - $1.count, weight: configuration.subtract($0.weight, $1.weight)) }
			)

			self.init(storage: Storage(configuration: config), count: 0)
		}

		init(storage: Storage, count: Int) {
			precondition(count >= 0)
			
			self.storage = storage
			self.count = count
		}

		/// Returns the local branch record index for the node holding a more deeply-nested index.
		///
		/// We can avoid reconstructing the full `NodeWeight` object here, because we only need to consider total counts.
		func localIndex(representing target: Index) -> Index? {
			let lastIndex = storage.endIndex - 1

			return storage.binarySearch { branchEntry, storageIndex in
				let totalCount = branchEntry.dependency.count + branchEntry.weight.count

				// this tricky business here allows for the target exactly one past the end to match, but
				// only if it is the very last index
				if lastIndex == storageIndex {
					return target <= totalCount
				} else {
					return target < totalCount
				}
			}
		}

		mutating func split() -> Storage.WeightedValue {
			let (left, right) = storage.halve()

			precondition(left.isEmpty == false)
			precondition(right.isEmpty == false)

			// update the left node
			self.storage = Storage(left)

			// create the new (right) node, and deal with the weights/counts
			let newStorage = Storage(right)
			let startWeight = newStorage[0].weight.weight
			let nodeWeight = Branch.NodeWeight(count: right.count, weight: startWeight)
			let newCount = newStorage.reduce(0, { $0 + $1.weightedValue.weight.count })
			let newBranch = Branch(storage: newStorage, count: newCount)

			let newNode = Node(newBranch)

			return .init(value: newNode, weight: nodeWeight)
		}
	}
}

extension RelativeList {
	final class Node {
		enum Kind {
			case branch(Branch)
			case leaf(Leaf)
		}

		var kind: Kind

		init(kind: Kind) {
			self.kind = kind
		}

		init(_ branch: Branch) {
			self.kind = .branch(branch)
		}

		/// All values stored in the entire subtree rooted at this node.
		var count: Int {
			switch kind {
			case let .leaf(leaf):
				leaf.storage.count
			case let .branch(branch):
				branch.count
			}
		}

		/// The contribution of everything contained in this node.
		var weight: Weight? {
			switch kind {
			case let .leaf(leaf):
				guard let record = leaf.storage.last else {
					return leaf.storage.configuration.initial
				}

				return leaf.storage.configuration.add(record.dependency, record.weight)
			case let .branch(branch):
				guard let record = branch.storage.last else {
					return branch.storage.configuration.initial.weight
				}

				return branch.storage.configuration.add(record.dependency, record.weight).weight
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

		func isTooFull(for capacity: Capacity) -> Bool {
			switch kind {
			case let .leaf(leaf):
				leaf.storage.count > capacity.leaf
			case let .branch(branch):
				branch.storage.count > capacity.branch
			}
		}

		func isFullEnough(_ capacity: Capacity) -> Bool {
			switch kind {
			case let .leaf(leaf):
				leaf.storage.count > capacity.leaf / 2
			case let .branch(branch):
				branch.count > capacity.branch / 2
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

extension RelativeList.Node {
	func record(at target: RelativeList.Index) -> RelativeList.Record {
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

extension RelativeList.Node {
	func recursivePrint(depth: Int, nodeWeight: RelativeList.Branch.NodeWeight) {
		let padding = String(repeating: "\t", count: depth)
		let offset = nodeWeight.count
		let weight = nodeWeight.weight

		switch kind {
		case let .branch(branch):
			print("\(padding)Branch: \(offset), \(weight), \(count)")

			for record in branch.storage {
				record.value.recursivePrint(depth: depth + 1, nodeWeight: record.weight)
			}
		case let .leaf(leaf):
			let content = leaf.storage
				.map({ $0.debugDescription })
				.joined(separator: ", ")

			print("\(padding)Leaf: \(offset), \(weight) [\(content)]")
		}
	}
}
