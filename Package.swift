// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "BigTime",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
		.watchOS(.v11),
		.tvOS(.v17),
		.visionOS(.v1),
	],
	products: [
		.library(
			name: "BigTime",
			targets: ["BigTime"]
		)
	],
	targets: [
		.target(
			name: "BigTime"
		),
		.testTarget(
			name: "BigTimeTests",
			dependencies: ["BigTime"]
		),
	]
)
