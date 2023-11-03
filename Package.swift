// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "RelativeCollections",
	products: [
		.library(name: "RelativeCollections", targets: ["RelativeCollections"]),
	],
	targets: [
		.target(name: "RelativeCollectionsInternal"),
		.testTarget(name: "RelativeCollectionsInternalTests", dependencies: ["RelativeCollectionsInternal"]),

		.target(name: "RelativeCollections", dependencies: ["RelativeCollectionsInternal"]),
		.testTarget(name: "RelativeCollectionsTests", dependencies: ["RelativeCollections"]),
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
