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

let swiftSettings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

for target in package.targets {
	var settings = target.swiftSettings ?? []
	settings.append(contentsOf: swiftSettings)
	target.swiftSettings = settings
}
