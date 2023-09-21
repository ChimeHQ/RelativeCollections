extension DependantList {
	struct NewLeaf {
		var storage: DependantArray<Value, Weight>
		var next: Node?

		var nextLeaf: Leaf? {
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
		struct Entry {
			let values: Int
			let weight: Weight
			let node: Node
		}

		var storage: [Entry]
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

//		func record(at index: Index) -> Record {
//			switch kind {
//			case let .leaf(leaf):
//				leaf.storage[index]
//			case let .branch(branch):
//				
//			}
//		}
	}
}
