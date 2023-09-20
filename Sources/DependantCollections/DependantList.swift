import DependantCollectionsInternal

public final class DependantList<Value, Weight> where Weight : AdditiveArithmetic {
	public typealias WeightedValue = DependantArray<Value, Weight>.WeightedValue
	public typealias Record = DependantArray<Value, Weight>.Record
	public typealias Predicate = DependantArray<Value, Weight>.Predicate

	typealias LeafStorage = DependantArray<Value, Weight>

	struct Position {
		let node: Node
		let index: LeafStorage.Index
	}

	private var root: Node

	public init(internalCapacity: Int = 10, leafCapacity: Int = 100) {
		self.root = Node(kind: .leaf(Leaf()))
	}
}

extension DependantList {
	struct Leaf {
		var indexOffset: Index
		var records: LeafStorage
		var next: Node?

		init() {
			self.indexOffset = 0
			self.records = LeafStorage()
			self.next = nil
		}
		
		var count: Int {
			records.count
		}
	}

	final class Node {
		enum Kind {
			case internalNode
			case leaf(Leaf)
		}

		var kind: Kind

		init(kind: Kind) {
			self.kind = kind
		}

		var recordCount: Int {
			switch self.kind {
			case .internalNode:
				0
			case let .leaf(leaf):
				leaf.count
			}
		}
	}
}

extension DependantList {
	public func append(_ value: WeightedValue) {
		insert(value, at: endIndex)
	}

	private func insert(_ value: WeightedValue, at index: Index) {
		internalInsert(value, using: { $1 >= index })
	}

	private func internalInsert(_ weighted: WeightedValue, using predicate: Predicate) {
		let position = findPosition(in: root, using: predicate)

		guard case var .leaf(leaf) = position.node.kind else { preconditionFailure() }

		leaf.records.insert(weighted, at: position.index)

		position.node.kind = .leaf(leaf)
	}

	private func findPosition(in node: Node, using predicate: Predicate) -> Position {
		switch node.kind {
		case let .leaf(leaf):
			let offset = leaf.indexOffset
			let idx = leaf.records.binarySearch(predicate: { predicate($0, $1 + offset) })

			return Position(node: node, index: idx ?? leaf.records.endIndex)
		case .internalNode:
			fatalError()
		}
	}

	private func findPosition(in node: Node, at index: Index) -> Position {
		switch node.kind {
		case let .leaf(leaf):
			let offset = leaf.indexOffset
			return Position(node: node, index: index - offset)
		case .internalNode:
			fatalError()
		}
	}

	public func replace(_ weighted: WeightedValue, at index: Index) {
		let position = findPosition(in: root, at: index)

		guard case var .leaf(leaf) = position.node.kind else { preconditionFailure() }

		leaf.records.replace(weighted, at: position.index)

		position.node.kind = .leaf(leaf)
	}
}

extension DependantList where Weight : Comparable {

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
			// TODO: this is totally wrong
			let pos = findPosition(in: root, at: position)

			guard case let .leaf(leaf) = pos.node.kind else { preconditionFailure() }

			yield leaf.records[pos.index]
		}
	}
}

