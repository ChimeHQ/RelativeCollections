import XCTest

import DPlusTree

final class BinarySearchTests: XCTestCase {
	func testEmptyArray() {
		let array: [Int] = []

		let ascIdx = array.binarySearch(predicate: { $0 == 0 })

		XCTAssertNil(ascIdx)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 == 0 })

		XCTAssertNil(descIdx)
	}

	func testSingleElementArray() {
		let array: [Int] = [0]

		let ascIdx = array.binarySearch(predicate: { $0 > -1 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 1 })

		XCTAssertEqual(descIdx, 0)
	}

	func testNotFoundInSingleElementArray() {
		let array: [Int] = [0]

		let ascIdx = array.binarySearch(predicate: { $0 == 1 })

		XCTAssertNil(ascIdx)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 == 1 })

		XCTAssertNil(descIdx)
	}

	func testFirstMatchInTwoElementArray() {
		let array: [Int] = [0, 1]

		let ascIdx = array.binarySearch(predicate: { $0 > -1 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 1 })

		XCTAssertEqual(descIdx, 0)
	}

	func testSecondMatchInTwoElementArray() {
		let array: [Int] = [0, 1]

		let ascIdx = array.binarySearch(predicate: { $0 > 0 })

		XCTAssertEqual(ascIdx, 1)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 2 })

		XCTAssertEqual(descIdx, 1)
	}

	func testNoMatchInTwoElementArray() {
		let array: [Int] = [0, 1]

		let ascIdx = array.binarySearch(predicate: { $0 > 2 })

		XCTAssertNil(ascIdx)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 0 })

		XCTAssertNil(descIdx)
	}

	func testThreeElementsAllTheSame() {
		let array: [Int] = [1, 1, 1]

		let ascIdx = array.binarySearch(predicate: { $0 == 1 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 == 1 })

		XCTAssertEqual(descIdx, 2)
	}

	func testFirstMatchInThreeElementArray() {
		let array: [Int] = [1, 2, 3]

		let ascIdx = array.binarySearch(predicate: { $0 > 0 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 2 })

		XCTAssertEqual(descIdx, 0)
	}

	func testFourElements() {
		let array: [Int] = [1, 2, 3, 4, 5]

		let ascIdx = array.binarySearch(predicate: { $0 > 2 })

		XCTAssertEqual(ascIdx, 2)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 4 })

		XCTAssertEqual(descIdx, 2)
	}

	func testFirstMatchWithFourElements() {
		let array: [Int] = [1, 2, 3, 4, 5]

		let ascIdx = array.binarySearch(predicate: { $0 > 0 })

		XCTAssertEqual(ascIdx, 0)

		let descIdx = array.binarySearch(direction: .descending, predicate: { $0 < 2 })

		XCTAssertEqual(descIdx, 0)
	}
}


