import XCTest

import DependantCollections

final class DependantListTests: XCTestCase {
	typealias AbsoluteRange = DependantArrayTests.AbsoluteRange
	typealias RelativeRange = DependantArrayTests.RelativeRange
	typealias TestList = DependantList<RelativeRange, Int, AbsoluteRange>

	static let listConfiguration: TestList.Configuration = {
		let arrayConfig = DependantArrayTests.arrayConfiguration

		return TestList.Configuration(
			leafCapacity: 5,
			internalCapacity: 5,
			decompose: arrayConfig.decompose,
			compose: arrayConfig.compose,
			integrate: arrayConfig.integrate,
			separate: arrayConfig.separate,
			initial: arrayConfig.initial
		)
	}()

	private static func makeList() -> TestList {
		return TestList(configuration: listConfiguration)
	}

	func testEmptyInsert() {
		var list = Self.makeList()

		list.insert(.init(name: "a", value: 0..<1))

		let expected: [AbsoluteRange] = [
			.init(name: "a", value: 0..<1),
		]

		XCTAssertEqual(Array(list), expected)
	}
}
