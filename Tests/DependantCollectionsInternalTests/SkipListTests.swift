import XCTest

import DependantCollectionsInternal

// see https://github.com/kodecocodes/swift-algorithm-club/tree/master/Skip-List
final class SkipListTests: XCTestCase {
	func testInsert() {
		let list = SkipList<String, Int>()

		list["a"] = 5

		XCTAssertEqual(list["a"], 5)
	}

	func testOverwriteKey() {
		let list = SkipList<String, Int>()

		list["a"] = 5

		XCTAssertEqual(list["a"], 5)

		list["a"] = 6

		XCTAssertEqual(list["a"], 6)
	}

	func testRemove() {
		let list = SkipList<String, Int>()

		list["a"] = 5

		XCTAssertEqual(list["a"], 5)

		list["a"] = nil

		XCTAssertEqual(list["a"], nil)
	}

	func testRemoveLastElement() {
		let list = SkipList<String, Int>()

		list["a"] = 5
		list["b"] = 6
		list["c"] = 7

		list["c"] = nil

		XCTAssertEqual(list["a"], 5)
		XCTAssertEqual(list["b"], 6)
		XCTAssertEqual(list["c"], nil)
	}

	func testRemoveKeyNotInList() {
		let list = SkipList<String, Int>()

		list["a"] = nil

		XCTAssertEqual(list["a"], nil)
	}
}
