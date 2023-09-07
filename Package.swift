// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "SpanList",
	products: [
		.library(name: "SpanList", targets: ["SpanList"]),
	],
	targets: [
		.target(name: "DPlusTree"),
		.testTarget(name: "DPlusTreeTests", dependencies: ["DPlusTree"]),

		.target(name: "SpanList"),
		.testTarget(name: "SpanListTests", dependencies: ["SpanList"]),
	]
)
