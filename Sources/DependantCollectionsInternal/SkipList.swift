public final class SkipList<Key: Comparable, Value> {
	private var head: Node?

	public init() {
	}
}

extension SkipList {
	final class Node {
		var data: Value?
		fileprivate var key: Key?
		var next: Node?
		var down: Node?

		public init() {
		}

		public init(key: Key, data: Value) {
			self.key  = key
			self.data = data
		}
	}
}

extension SkipList {
	func insert(_ value: Value, for key: Key) {
		guard head != nil else {
			bootstrapBaseLayer(key: key, data: value)
			return
		}

		guard let node = findNode(for: key) else {
			insertItem(key: key, data: value)
			return
		}

		// replace, in case of key already exists.
		var currentNode = node.next
		while let node = currentNode, node.key == key {
			node.data = value
			currentNode = node.down
		}
	}
}

extension SkipList {
	func findNode(for key: Key) -> Node? {
		var currentNode: Node? = head
		var isFound = false

		while !isFound, let node = currentNode {
			guard let next = node.next else {
				currentNode = node.down
				continue
			}

			if next.key == key {
				isFound = true
				break
			}

			guard let nextKey = next.key else {
				preconditionFailure("next.key cannot be nil")
			}

			if key < nextKey {
				currentNode = node.down
			} else {
				currentNode = node.next
			}
		}

		return isFound ? currentNode : nil
	}

	func search(key: Key) -> Value? {
		guard let node = findNode(for: key) else {
			return nil
		}

		guard let next = node.next else {
			preconditionFailure("next node must be set")
		}

		return next.data
	}

}

extension SkipList {
	private func bootstrapBaseLayer(key: Key, data: Value) {
		head       = Node()
		var node   = Node(key: key, data: data)

		head!.next = node

		var currentTopNode = node

		while Bool.random() {
			let newHead    = Node()
			node           = Node(key: key, data: data)
			node.down      = currentTopNode
			newHead.next   = node
			newHead.down   = head
			head           = newHead
			currentTopNode = node
		}
	}

	/// Insert a node into lanes depending on skip list status
	///
	/// And bootstrap base-layer if head is empty / start insertion from current head.
	private func insertItem(key: Key, data: Value) {
		var stack = ContiguousArray<Node>()
		var currentNode = head

		while let node = currentNode {
			guard let nextNode = node.next else {
				stack.append(node)
				currentNode = node.down
				continue
			}

			if nextNode.key! > key {
				stack.append(node)
				currentNode = node.down
			} else {
				currentNode = nextNode
			}
		}

		guard let itemAtLayer = stack.popLast() else {
			preconditionFailure("Missing layer item")
		}

		var node = Node(key: key, data: data)
		node.next          = itemAtLayer.next
		itemAtLayer.next  = node
		var currentTopNode = node

		while Bool.random() {
			if stack.isEmpty {
				let newHead = Node()

				node           = Node(key: key, data: data)
				node.down      = currentTopNode
				newHead.next   = node
				newHead.down   = head
				head           = newHead
				currentTopNode = node

				continue
			}

			guard let nextNode = stack.popLast() else {
				preconditionFailure("Stack has no more nodes")
			}

			node = Node(key: key, data: data)
			node.down = currentTopNode
			node.next = nextNode.next
			nextNode.next = node
			currentTopNode = node
		}
	}

	/// Remove a node with a given key.
	///
	/// First, find its position in layers at the top, then remove it from each lane by traversing down to the base layer.
	func remove(key: Key) {
		var currentNode = findNode(for: key)

		while let node = currentNode {
			guard let next = node.next else {
				preconditionFailure("A next node must be present")
			}

			if next.key != key {
				currentNode = next
				continue
			}

			node.next = next.next
			currentNode = node.down
		}
	}
}

extension SkipList {
	public subscript(index: Key) -> Value? {
		get {
			search(key: index)
		}
		set {
			if let value = newValue {
				insert(value, for: index)
			} else {
				remove(key: index)
			}
		}
	}
}
