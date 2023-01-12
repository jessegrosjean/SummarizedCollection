// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var settings: [SwiftSetting] = [

  // Enables internal consistency checks at the end of initializers and
  // mutating operations. This can have very significant overhead, so enabling
  // this setting invalidates all documented performance guarantees.
  //
  // This is mostly useful while debugging an issue with the implementation of
  // the hash table itself. This setting should never be enabled in production
  // code.
//  .define("COLLECTIONS_INTERNAL_CHECKS"),

  // Hashing collections provided by this package usually seed their hash
  // function with the address of the memory location of their storage,
  // to prevent some common hash table merge/copy operations from regressing to
  // quadratic behavior. This setting turns off this mechanism, seeding
  // the hash function with the table's size instead.
  //
  // When used in conjunction with the SWIFT_DETERMINISTIC_HASHING environment
  // variable, this enables reproducible hashing behavior.
  //
  // This is mostly useful while debugging an issue with the implementation of
  // the hash table itself. This setting should never be enabled in production
  // code.
//  .define("COLLECTIONS_DETERMINISTIC_HASHING"),

]

let package = Package(
    name: "SummarizedCollection",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .library(name: "SummarizedCollection", targets: ["SummarizedCollection"]),
        .executable(name: "SummarizedCollectionBenchmark", targets: ["SummarizedCollectionBenchmark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/peripheryapp/periphery", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.3"),
    ],
    targets: [
        
        .target(
            name: "SummarizedCollection",
            dependencies: ["_CollectionsUtilities"],
            swiftSettings: settings),

        .testTarget(
            name: "SummarizedCollectionTests",
            dependencies: ["SummarizedCollection", "_CollectionsTestSupport"],
            swiftSettings: settings),

        .target(
            name: "_CollectionsTestSupport",
            dependencies: ["_CollectionsUtilities"],
            swiftSettings: settings,
            linkerSettings: [
                .linkedFramework(
                    "XCTest",
                    .when(platforms: [.macOS, .iOS, .watchOS, .tvOS])),
            ]
        ),

        .target(
            name: "_CollectionsUtilities",
            swiftSettings: settings),
        
        .executableTarget(
            name: "SummarizedCollectionBenchmark",
            dependencies: [
                "SummarizedCollection",
                .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
            ]),
    ]
)
