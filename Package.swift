// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "JWTMiddleware",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "JWTMiddleware", targets: ["JWTMiddleware"]),
    ],
    dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3"),
    .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-beta.2"),
    ],
    targets: [
        .target(name: "JWTMiddleware", dependencies: ["Vapor", "JWT"]),
        .testTarget(name: "JWTMiddlewareTests", dependencies: ["JWTMiddleware"])
    ]
)
