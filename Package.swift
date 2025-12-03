// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "BigTime",
	platforms: [
		.iOS(.v18),
		.macOS(.v15),
		.watchOS(.v11),
		.tvOS(.v18),
		.visionOS(.v2),
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
