import XCTest

import DependantCollections

final class DependantArrayTests: XCTestCase {
	struct NamedThing<T>: Hashable, CustomDebugStringConvertible where T : Hashable{
		let name: String
		let value: T

		var debugDescription: String {
			"[\(name): \(value)]"
		}
	}

	typealias AbsoluteRange = NamedThing<Range<Int>>
	typealias RelativeRange = NamedThing<Int>

	typealias TestArray = DependantArray<RelativeRange, Int, AbsoluteRange>

	static let arrayConfiguration: TestArray.Configuration = {
		TestArray.Configuration(
			decompose: { absolute in
				let length = absolute.value.count
				let relative = RelativeRange(name: absolute.name, value: length)

				return TestArray.Record(independent: relative, dependency: absolute.value.upperBound)
			}, compose: { record in
				let name = record.independent.name
				let start = record.dependency
				let end = record.dependency + record.independent.value
				let absoluteRange = start..<end

				return AbsoluteRange(name: name, value: absoluteRange)
			}
		)
	}()

	private static func makeArray() -> TestArray {
		return TestArray(configuration: arrayConfiguration)
	}

	func testAppendInOrder() throws {
		var list = Self.makeArray()

		let expected: [AbsoluteRange] = [
			.init(name: "a", value: 0..<1),
			.init(name: "b", value: 1..<3),
			.init(name: "c", value: 3..<6),
		]

		for range in expected {
			list.append(range)
		}

		XCTAssertEqual(list.map { $0 }, expected)
	}

	func testRemoveFirst() throws {
		var list = Self.makeArray()

		list.append(.init(name: "a", value: 0..<1))
		list.append(.init(name: "b", value: 1..<3))
		list.append(.init(name: "c", value: 3..<6))

		// shift everything back by 1
		list.remove(at: 0)

		let expected: [AbsoluteRange] = [
			.init(name: "b", value: 0..<2),
			.init(name: "c", value: 2..<5),
		]

		XCTAssertEqual(list.map { $0 }, expected)
	}

	func testRemoveLast() throws {
		var list = Self.makeArray()

		list.append(.init(name: "a", value: 0..<1))
		list.append(.init(name: "b", value: 1..<3))
		list.append(.init(name: "c", value: 3..<6))

		list.remove(at: 2)

		let expected: [AbsoluteRange] = [
			.init(name: "a", value: 0..<1),
			.init(name: "b", value: 1..<3),
		]

		XCTAssertEqual(list.map { $0 }, expected)
	}

	func testReplaceFirst() throws {
		var list = Self.makeArray()

		list.append(.init(name: "a", value: 0..<1))
		list.append(.init(name: "b", value: 1..<3))
		list.append(.init(name: "c", value: 3..<6))

		// shift everything back by 2
		list[0] = .init(name: "d", value: 0..<2)

		let expected: [AbsoluteRange] = [
			.init(name: "d", value: 0..<2),
			.init(name: "b", value: 2..<4),
			.init(name: "c", value: 4..<7),
		]

		XCTAssertEqual(list.map { $0 }, expected)
	}

	func testEmptyInsert() {
		var list = Self.makeArray()

		list.insert(.init(name: "a", value: 0..<1))

		let expected: [AbsoluteRange] = [
			.init(name: "a", value: 0..<1),
		]

		XCTAssertEqual(list.map { $0 }, expected)
	}
}
