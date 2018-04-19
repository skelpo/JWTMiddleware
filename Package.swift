// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "JWTMiddlware",
    products: [
        .library(name: "JWTMiddlware", targets: ["JWTMiddlware"]),
    ],
    dependencies: [
    .package(url: "https://github.com/skelpo/vapor-request-storage.git", from: "0.1.0"),
        .package(url: "https://github.com/skelpo/JWTVapor.git", from: "0.6.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc")
    ],
    targets: [
        .target(name: "JWTAuthenticatable", dependencies: ["Vapor", "Authentication", "JWTVapor", "VaporRequestStorage"]),
        .target(name: "JWTMiddlware", dependencies: ["Vapor", "Authentication", "JWTVapor"]),
        .testTarget(name: "JWTMiddlwareTests", dependencies: ["JWTMiddlware"])
    ]
)
