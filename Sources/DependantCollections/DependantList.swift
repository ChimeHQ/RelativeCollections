public struct DependantList<Independent, Dependency, Element> where Element : Comparable {
	public typealias Array = DependantArray<Independent, Dependency, Element>
	public typealias Record = Array.Record
	public typealias Decompose = Array.Decompose
	public typealias Compose = Array.Compose
	public typealias Integrate = Array.Integrate
	public typealias Separate = Array.Separate

	public typealias Query<T: Comparable> = (Dependency) -> T

	let configuration: Configuration
	private let root: Node

	public init(configuration: Configuration) {
		self.configuration = configuration
		self.root = Node()
	}

}

extension DependantList {
	public struct Configuration {
		public let leafCapacity: Int
		public let internalCapacity: Int
		let arrayConfig: Array.Configuration

		public init(
			leafCapacity: Int = 100,
			internalCapacity: Int = 100,
			decompose: @escaping Decompose,
			compose: @escaping Compose,
			integrate: @escaping Integrate,
			separate: @escaping Separate,
			initial: Dependency
		) {
			self.leafCapacity = leafCapacity
			self.internalCapacity = internalCapacity

			self.arrayConfig = .init(decompose: decompose, compose: compose, integrate: integrate, separate: separate, initial: initial)
		}
	}
}

extension DependantList {
	public func insert(_ value: Element) {
//		let target = configuration.arrayConfig.decompose(value)
//
//		let (node, index, parent) = findLeaf(in: root, parent: nil, with: target.dependency, using: query)
//
//		
	}
//
//	func findLeaf<T: Comparable>(in node: Node, parent: Node?, with target: T, using query: Query<T>) -> (Node, Int, Node?) {
//		
//	}
}

extension DependantList : Sequence {
	public struct Iterator : IteratorProtocol {
		public mutating func next() -> Element? {
			nil
		}
	}

	public func makeIterator() -> Iterator {
		Iterator()
	}
}

extension DependantList {
	final class Node {
	}
}
