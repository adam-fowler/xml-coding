import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(xml_encoderTests.allTests),
    ]
}
#endif
