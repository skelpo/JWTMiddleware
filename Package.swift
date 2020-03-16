// swift-tools-version:5.2
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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-rc"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
    ],
    targets: [
        .target(name: "JWTMiddleware", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "JWT", package: "jwt"),
        ]),
        .testTarget(name: "JWTMiddlewareTests", dependencies: [
            .byName(name: "JWTMiddleware"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
