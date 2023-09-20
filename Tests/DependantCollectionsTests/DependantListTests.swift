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

	func testUpdateFirst() throws {
		let list = TestList()

		for length in [1, 2, 3, 4] {
			list.append(.init(weight: length))
		}

		list.replace(.init(weight: 5), at: 0)
		
		let expected = [5, 2, 3, 4]

		XCTAssertEqual(list.map { $0.value }, expected)
	}
}
