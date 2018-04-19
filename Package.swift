// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "JWTMiddlware",
    products: [
        .library(name: "JWTMiddlware", targets: ["JWTMiddlware"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc"),
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0-rc")
    ],
    targets: [
        .target(name: "JWTMiddlware", dependencies: ["Vapor", "Authentication", "JWT"]),
        .testTarget(name: "JWTMiddlwareTests", dependencies: ["JWTMiddlware"]),
    ]
)
