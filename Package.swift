// swift-tools-version:4.0
import PackageDescription
let package = Package(
    name: "JWTMiddlware",
    products: [
        .library(name: "JWTMiddlware", targets: ["JWTMiddlware"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "JWTMiddlware", dependencies: []),
        .testTarget(name: "JWTMiddlwareTests", dependencies: ["JWTMiddlware"]),
    ]
)