import XCTest

import RelativeCollections

final class RelativeArrayTests: XCTestCase {
	typealias TestArray = RelativeArray<Int, Int>

	func testAppend() throws {
		var array = TestArray()

		let expected = [
			0..<1,
			1..<3,
			3..<6,
			6..<10
		]

		for range in expected {
			array.append(.init(value: range.count, weight: range.count))
		}

		let rebuilt = array.map { $0.dependency..<($0.dependency + $0.value) }

		XCTAssertEqual(rebuilt, expected)
	}

	func testUpdateFirst() throws {
		var array = TestArray()

		let ranges = [
			0..<1,
			1..<3,
			3..<6,
			6..<10
		]

		// insert lengths
		for range in ranges {
			array.append(.init(value: range.count, weight: range.count))
		}

		array.replace(.init(value: 5, weight: 5), at: 0)

		let rebuilt = array.map { $0.dependency..<($0.dependency + $0.value) }

		let expected = [
			0..<5,
			5..<7,
			7..<10,
			10..<14
		]

		XCTAssertEqual(rebuilt, expected)
	}

	func testUpdateLast() throws {
		var array = TestArray()

		let ranges = [
			0..<1,
			1..<3,
			3..<6,
			6..<10
		]

		// insert lengths
		for range in ranges {
			array.append(.init(value: range.count, weight: range.count))
		}

		array.replace(.init(value: 5, weight: 5), at: 3)

		let rebuilt = array.map { $0.dependency..<($0.dependency + $0.value) }

		let expected = [
			0..<1,
			1..<3,
			3..<6,
			6..<11
		]

		XCTAssertEqual(rebuilt, expected)
	}

	func testRemoveFirst() {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(value: length, weight: length))
		}

		array.remove(at: 0)

		let expected = [2, 3, 4]

		XCTAssertEqual(array.map { $0.value }, expected)
	}

	func testInsertWithPredicate() {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(value: length, weight: length))
		}

		array.insert(.init(value: 5, weight: 5)) { _, idx in
			return idx >= 1
		}

		let expected = [1, 5, 2, 3, 4]

		XCTAssertEqual(array.map { $0.value }, expected)
	}

	func testInsertAtBeginning() {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(value: length, weight: length))
		}

		array.insert(.init(value: 5, weight: 5), at: 0)

		let expected = [5, 1, 2, 3, 4]

		XCTAssertEqual(array.map { $0.value }, expected)
	}

	func testInsertWithPredicateAtFirst() {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(value: length, weight: length))
		}

		array.insert(.init(value: 5, weight: 5)) { _, idx in
			return idx >= 0
		}

		let expected = [5, 1, 2, 3, 4]

		XCTAssertEqual(array.map { $0.value }, expected)
	}

	func testSubscriptAndRecordAreTheSame() {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(value: length, weight: length))
		}

		XCTAssertEqual(array[0], array.record(at: 0))
		XCTAssertEqual(array[1], array.record(at: 1))
		XCTAssertEqual(array[2], array.record(at: 2))
	}
}

extension RelativeArrayTests {
	func testIterator() throws {
		var array = TestArray()

		// append lengths in a random order
		for length in [1, 2, 3, 4].shuffled() {
			array.append(.init(value: length, weight: length))
		}

		XCTAssertEqual(Array(array), array.map { $0 } )
	}

	func testRangeReplacement() throws {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(weight: length))
		}

		array.replaceSubrange(1..<3, with: [
			TestArray.WeightedValue(weight: 8),
			TestArray.WeightedValue(weight: 9)
		])

		let expected = [1, 8, 9, 4]

		XCTAssertEqual(array.map { $0.value }, expected)
	}

	func testRangeReplacementEntireArray() throws {
		var array = TestArray()

		for length in [1, 2, 3, 4] {
			array.append(.init(weight: length))
		}

		array.replaceSubrange(0..<4, with: [
			TestArray.WeightedValue(weight: 8),
			TestArray.WeightedValue(weight: 9)
		])

		let expected = [8, 9]

		XCTAssertEqual(array.map { $0.value }, expected)
	}
}
