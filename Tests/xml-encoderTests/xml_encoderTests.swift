import XCTest
@testable import xml_encoder

final class xml_encoderTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(xml_encoder().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
