public struct DependantList<Independent, Dependency, Element> where Dependency : Comparable {
	public typealias Array = DependantArray<Independent, Dependency, Element>
	public typealias Record = Array.Record
	public typealias Decompose = Array.Decompose
	public typealias Compose = Array.Compose
	public typealias Integrate = Array.Integrate
	public typealias Separate = Array.Separate

	public typealias Query<T: Comparable> = (Dependency) -> T

	let configuration: Configuration

	public init(configuration: Configuration) {
		self.configuration = configuration
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

	}
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
