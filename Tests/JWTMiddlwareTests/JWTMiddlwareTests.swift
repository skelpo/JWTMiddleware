import XCTest
@testable import JWTMiddlware

final class JWTMiddlwareTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(JWTMiddlware().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
