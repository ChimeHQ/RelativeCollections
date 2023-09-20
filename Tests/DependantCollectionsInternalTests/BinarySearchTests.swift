import XCTest

import DependantCollectionsInternal

final class BinarySearchTests: XCTestCase {
	func testEmptyArray() {
		let array: [Int] = []

		let ascIdx = array.binarySearch(predicate: { value, _ in value == 0 })

		XCTAssertNil(ascIdx)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value == 0 })

		XCTAssertNil(descIdx)
	}

	func testSingleElementArray() {
		let array: [Int] = [0]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > -1 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 1 })

		XCTAssertEqual(array.index(before: descIdx!.base), 0)
	}

	func testNotFoundInSingleElementArray() {
		let array: [Int] = [0]

		let ascIdx = array.binarySearch(predicate: { value, _ in value == 1 })

		XCTAssertNil(ascIdx)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value == 1 })

		XCTAssertNil(descIdx)
	}

	func testFirstMatchInTwoElementArray() {
		let array: [Int] = [0, 1]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > -1 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 1 })

		XCTAssertEqual(array.index(before: descIdx!.base), 0)
	}

	func testSecondMatchInTwoElementArray() {
		let array: [Int] = [0, 1]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > 0 })

		XCTAssertEqual(ascIdx, 1)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 2 })

		XCTAssertEqual(array.index(before: descIdx!.base), 1)
	}

	func testNoMatchInTwoElementArray() {
		let array: [Int] = [0, 1]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > 2 })

		XCTAssertNil(ascIdx)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 0 })

		XCTAssertNil(descIdx)
	}

	func testThreeElementsAllTheSame() {
		let array: [Int] = [1, 1, 1]

		let ascIdx = array.binarySearch(predicate: { value, _ in value == 1 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value == 1 })

		XCTAssertEqual(array.index(before: descIdx!.base), 2)
	}

	func testFirstMatchInThreeElementArray() {
		let array: [Int] = [1, 2, 3]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > 0 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 2 })

		XCTAssertEqual(array.index(before: descIdx!.base), 0)
	}

	func testFourElements() {
		let array: [Int] = [1, 2, 3, 4, 5]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > 2 })

		XCTAssertEqual(ascIdx, 2)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 4 })

		XCTAssertEqual(array.index(before: descIdx!.base), 2)
	}

	func testFirstMatchWithFourElements() {
		let array: [Int] = [1, 2, 3, 4, 5]

		let ascIdx = array.binarySearch(predicate: { value, _ in value > 0 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.reversed().binarySearch(predicate: { value, _ in value < 2 })

		XCTAssertEqual(array.index(before: descIdx!.base), 0)
	}
}
