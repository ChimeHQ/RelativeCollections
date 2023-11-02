import XCTest

import DependantCollections

final class DependantListTests: XCTestCase {
	typealias TestList = DependantList<Int, Int>

	func testAppend() throws {
		let list = TestList()

		for length in [1, 2, 3, 4] {
			list.append(.init(weight: length))
		}

		let expected = [1, 2, 3, 4]

		XCTAssertEqual(list.map { $0.value }, expected)
	}

	func testInsertAtBeginning() throws {
		let list = TestList()

		for length in [1, 2, 3, 4] {
			list.append(.init(weight: length))
		}

		list.insert(.init(weight: 5), at: 0)

		let expected = [5, 1, 2, 3, 4]

		XCTAssertEqual(list.map { $0.value }, expected)
	}

	func testInsertAtEnd() throws {
		let list = TestList()

		for length in [1, 2, 3, 4] {
			list.append(.init(weight: length))
		}

		list.insert(.init(weight: 5), at: list.endIndex)

		let expected = [1, 2, 3, 4, 5]

		XCTAssertEqual(list.map { $0.value }, expected)
	}

//	func testUpdateFirst() throws {
//		let list = TestList()
//
//		for length in [1, 2, 3, 4] {
//			list.append(.init(weight: length))
//		}
//
//		list.replace(.init(weight: 5), at: 0)
//		
//		let expected = [5, 2, 3, 4]
//
//		XCTAssertEqual(list.map { $0.value }, expected)
//	}

//	func testRemoveFirst() throws {
//		let list = TestList()
//
//		for length in [1, 2, 3, 4] {
//			list.append(.init(weight: length))
//		}
//
//		list.remove(at: 0)
//
//		let expected = [2, 3, 4]
//
//		XCTAssertEqual(list.map { $0.value }, expected)
//	}
}

extension DependantListTests {
	func testSplitRoot() {
		let capacity = TestList.Capacity(leaf: 2, branch: 2)
		let list = TestList(configuration: .init(capacity: capacity))

		for length in [1, 2, 3, 4] {
			list.append(.init(weight: length))
		}

		let expected = [1, 2, 3, 4]

		XCTAssertEqual(list.map { $0.value }, expected)
	}
}
