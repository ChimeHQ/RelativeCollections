extension DependantList {
	struct NewLeaf {
		var storage: DependantArray<Value, Weight>
		var next: NewNode?

		var nextLeaf: NewLeaf? {
			guard let next = next else { return nil }

			guard case let .leaf(leaf) = next.kind else {
				preconditionFailure("Leaf next does not point to a leaf node")
			}

			return leaf
		}
	}
}

extension DependantList {
	struct Branch {
		struct NodeWeight : Comparable {
			let count: Int
			let weight: Weight

			static func < (lhs: Self, rhs: Self) -> Bool {
				lhs.weight < rhs.weight
			}
		}

		var storage: DependantArray<NewNode, NodeWeight>

		init(configuration: DependantList.LeafStorage.Configuration) {
			let config = DependantArray<NewNode, NodeWeight>.Configuration(
				initial: NodeWeight(count: 0, weight: configuration.initial),
				add: { NodeWeight(count: $0.count + $1.count, weight: configuration.add($0.weight, $0.weight)) },
				subtract: { NodeWeight(count: $0.count - $1.count, weight: configuration.subtract($0.weight, $0.weight)) }
			)

			self.storage = DependantArray(configuration: config)
		}
	}
}
extension DependantList {
	final class NewNode {
		enum Kind {
			case branch(Branch)
			case leaf(NewLeaf)
		}

		var kind: Kind

		init(kind: Kind) {
			self.kind = kind
		}

		func record(at target: Index) -> Record {
			switch kind {
			case let .leaf(leaf):
				return leaf.storage[target]
			case let .branch(branch):
				// we can avoid reconstructing the full NodeWeight object here, because we only need to consider total counts
				let entryIndex = branch.storage.binarySearch { branchEntry, storageIndex in
					let totalCount = branchEntry.dependency.count + branchEntry.weight.count

					return target <= totalCount
				}

				guard let entryIndex else {
					preconditionFailure("Index isn't in this node")
				}

				let branchEntry = branch.storage[entryIndex]
				let node = branchEntry.value
				let adjustedTarget = target - branchEntry.dependency.count

				return node.record(at: adjustedTarget)
			}
		}
	}
}
