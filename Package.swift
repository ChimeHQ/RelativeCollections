// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "DependantCollections",
	products: [
		.library(name: "DependantCollections", targets: ["DependantCollections"]),
	],
	targets: [
		.target(name: "DependantCollectionsInternal"),
		.testTarget(name: "DependantCollectionsInternalTests", dependencies: ["DependantCollectionsInternal"]),

		.target(name: "DependantCollections", dependencies: ["DependantCollectionsInternal"]),
		.testTarget(name: "DependantCollectionsTests", dependencies: ["DependantCollections"]),
	]
)
