import XCTest
@testable import bez

final class bezTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(bez().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
