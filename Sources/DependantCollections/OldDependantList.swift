//public struct DependantList<Element, Weight> {
//	public struct Record {
//		let value: Element
//		let dependency: Weight
//	}
//
//	public typealias ComputeWeight = (Element) -> Weight
//	public typealias CombineWeights = (Weight, Weight) -> Weight
//	public typealias SeparateWeights = (Weight, Weight) -> Weight
//	public typealias Comparator = (Record, Record) -> Bool
//	public typealias Predicate = (Record) -> Bool
//
//	let configuration: Configuration
//	private let root: Node
//
//	public init(configuration: Configuration) {
//		self.configuration = configuration
//		self.root = Node.leaf
//	}
//}
//
//extension DependantList {
//	public struct Configuration {
//		public let leafCapacity: Int
//		public let internalCapacity: Int
//		public let computeWeight: ComputeWeight
//		public let combineWeights: CombineWeights
//		public let separateWeights: SeparateWeights
//		public let comparator: Comparator
//		public let initial: Weight
//
//		public init(
//			leafCapacity: Int = 100,
//			internalCapacity: Int = 100,
//			computeWeight: @escaping ComputeWeight,
//			combineWeights: @escaping CombineWeights,
//			separateWeights: @escaping SeparateWeights,
//			comparator: @escaping Comparator,
//			initial: Weight
//		) {
//			self.leafCapacity = leafCapacity
//			self.internalCapacity = internalCapacity
//			self.computeWeight = computeWeight
//			self.combineWeights = combineWeights
//			self.separateWeights = separateWeights
//			self.comparator = comparator
//			self.initial = initial
//		}
//	}
//}
//
//extension DependantList {
//	public func insert(_ value: Element, using predicate: Predicate) {
//		var weight = configuration.initial
//
//		let node = findLeaf(in: root, weight: &weight, using: predicate)
//
//		guard case var .leaf(leaf) = node.kind else { preconditionFailure() }
//
//		let record = Record(value: value, dependency: weight)
//
//		leaf.records.insert(record)
//
//	}
//
//	private func findLeaf(in node: Node, weight: inout Weight, using predicate: Predicate) -> Node {
//		switch node.kind {
//		case .leaf:
//			return node
//		case .internalNode:
//			fatalError()
//		}
//	}
//}
//
////extension DependantList : Sequence {
////	public struct Iterator : IteratorProtocol {
////		private var node: Node?
////		private var index: Array.Index
////
////		init(node: Node) {
////			self.node = node
////
////			guard case let .leaf(leaf) = node.kind else { preconditionFailure() }
////
////			self.index = leaf.records.startIndex
////		}
////
////		public mutating func next() -> Element? {
////			guard let currentNode = node else { return nil }
////			guard case let .leaf(leaf) = currentNode.kind else { preconditionFailure() }
////
////			if index == leaf.records.endIndex {
////				return nil
////			}
////
////			let value = leaf.records[index]
////
////			index = leaf.records.index(after: index)
////			if index >= leaf.records.endIndex {
////				node = leaf.next
////			}
////
////			return value
////		}
////	}
////
////	public func makeIterator() -> Iterator {
////		Iterator(node: root)
////	}
////}
//
//extension DependantList {
//	struct Leaf {
//		var records: [Record]
//		var next: Node?
//
//		var count: Int {
//			records.count
//		}
//	}
//
//	struct Internal {
//	}
//
//	final class Node {
//		enum Kind {
//			case internalNode(Internal)
//			case leaf(Leaf)
//		}
//
//		var kind: Kind
//
//		init(kind: Kind) {
//			self.kind = kind
//		}
//	}
//}
