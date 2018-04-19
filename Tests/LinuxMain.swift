import XCTest

import JWTMiddlwareTests

var tests = [XCTestCaseEntry]()
tests += JWTMiddlwareTests.allTests()
XCTMain(tests)