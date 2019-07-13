import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(XMLTests.allTests),
        testCase(XMLEncoderTests.allTests)
    ]
}
#endif
