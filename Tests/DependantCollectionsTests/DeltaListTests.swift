import XCTest

import DependantCollections

struct IntegerPair: Comparable, AdditiveArithmetic {
	let a: Int
	let b: Int

	public init(_ a: Int, _ b: Int) {
		self.a = a
		self.b = b
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.a < rhs.a
	}

	static var zero = IntegerPair(0, 0)

	static func + (lhs: Self, rhs: Self) -> Self {
		IntegerPair(lhs.a + rhs.a, lhs.b + rhs.b)
	}

	static func - (lhs: Self, rhs: Self) -> Self {
		IntegerPair(lhs.a - rhs.a, lhs.b - rhs.b)
	}
}

extension IntegerPair: CustomDebugStringConvertible {
	var debugDescription: String {
		"[\(a), \(b)]"
	}
}

final class DeltaListTests: XCTestCase {
	typealias List = DeltaList<IntegerPair, String>

	func testSingleLeafInOrderInsertion() {
		let order = 10
		let list = List(order: order)

		let expected: [List.Record] = [
			.init(key: IntegerPair(0, 10), value: "a"),
			.init(key: IntegerPair(10, 9), value: "b"),
			.init(key: IntegerPair(19, 8), value: "c"),
			.init(key: IntegerPair(27, 7), value: "d"),
			.init(key: IntegerPair(34, 6), value: "e"),
			.init(key: IntegerPair(40, 5), value: "f"),
			.init(key: IntegerPair(45, 4), value: "g"),
		]

		XCTAssert(expected.count < order)
		
		for keyedRecord in expected {
			list.insert(keyedRecord)
		}

		XCTAssertEqual(list.lookup(0, using: { $0.a }), expected[0])
	}
}
