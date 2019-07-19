//
//  XMLTests.swift
//  AWSSDKSwiftCoreTests
//
//  Created by Adam Fowler 2019/07/06
//

import Foundation
import XCTest
@testable import xml_encoder

class XMLTests: XCTestCase {

    /// helper test function to use throughout all the decode/encode tests
    func testDecodeEncode(xml: String, options: XML.Options = []) {
        do {
            let xmlDocument = try XML.Document(data: xml.data(using: .utf8)!, options: options)
            let xml2 = xmlDocument.xmlString(options: options)
            XCTAssertEqual(xml, xml2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testAddChild() {
        let element = XML.Element(name:"test")
        let element2 = XML.Element(name:"test2")
        element.addChild(element2)
        element2.addChild(XML.Node.text(stringValue: "TestString"))
        XCTAssertEqual(element.xmlString, "<test><test2>TestString</test2></test>")
    }
    func testAddRemoveChild() {
        let element = XML.Element(name:"test")
        let element2 = XML.Element(name:"test2")
        element.addChild(element2)
        element2.addChild(XML.Node.text(stringValue: "TestString"))
        element2.detach()
        XCTAssertEqual(element.xmlString, "<test></test>")
    }
    func testAttributeAdd() {
        let element = XML.Element(name:"test", stringValue: "data")
        element.addAttribute(XML.Node.attribute(withName: "attribute", stringValue: "value"))
        XCTAssertEqual(element.xmlString, "<test attribute=\"value\">data</test>")
    }
    func testAttributeReplace() {
        let element = XML.Element(name:"test", stringValue: "data")
        element.addAttribute(XML.Node.attribute(withName: "attribute", stringValue: "value"))
        element.addAttribute(XML.Node.attribute(withName: "attribute", stringValue: "value2"))
        XCTAssertEqual(element.xmlString, "<test attribute=\"value2\">data</test>")
    }
    func testNamespaceAdd() {
        let element = XML.Element(name:"test", stringValue: "data")
        element.addNamespace(XML.Node.namespace(withName: "name", stringValue: "http://me.com/"))
        XCTAssertEqual(element.xmlString, "<test xmlns:name=\"http://me.com/\">data</test>")
    }
    func testNamespaceReplace() {
        let element = XML.Element(name:"test", stringValue: "data")
        element.addNamespace(XML.Node.namespace(withName: "name", stringValue: "http://me.com/"))
        element.addNamespace(XML.Node.namespace(withName: "name", stringValue: "http://me2.com/"))
        XCTAssertEqual(element.xmlString, "<test xmlns:name=\"http://me2.com/\">data</test>")
    }
    func testNullNamespaceReplace() {
        let element = XML.Element(name:"test", stringValue: "data")
        element.addNamespace(XML.Node.namespace(stringValue: "http://me.com/"))
        element.addNamespace(XML.Node.namespace(stringValue: "http://me2.com/"))
        XCTAssertEqual(element.xmlString, "<test xmlns=\"http://me2.com/\">data</test>")
    }
    func testDocumentDefaultOutput() {
        let document = XML.Node.document()
        XCTAssertEqual(document.xmlString, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    }
    func testAttributesDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test name=\"test\">testing</test>"
        testDecodeEncode(xml: xml)
    }
    func testNamespacesDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test xmlns:h=\"http://www.w3.org/TR/html4/\">testing</test>"
        testDecodeEncode(xml: xml)
    }
    func testArrayDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><array><test>testing1</test><test>testing2</test><test>testing3</test></array>"
        testDecodeEncode(xml: xml)
    }
    func testCommentDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test>testing<!--Test Comment--></test>"
        testDecodeEncode(xml: xml)
    }
    func testCDATADecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test><![CDATA[CDATA test]]></test>"
        do {
            let xmlDocument = try XML.Document(data: xml.data(using: .utf8)!)
            let xml1 = xmlDocument.xmlString
            let xmlDocument2 = try XML.Document(data: xml.data(using: .utf8)!, options: .nodePreserveCDATA)
            let xml2 = xmlDocument2.xmlString
            XCTAssertEqual(xml1, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test>CDATA test</test>")
            XCTAssertEqual(xml2, xml)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testWhitespaceDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test> <a> before</a><b></b> <c>after </c></test>"
        do {
            let xmlDocument = try XML.Document(xmlString: xml)
            let xml1 = xmlDocument.xmlString
            let xmlDocument2 = try XML.Document(xmlString: xml, options: .nodePreserveWhitespace)
            let xml2 = xmlDocument2.xmlString
            XCTAssertEqual(xml1, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test><a> before</a><b></b><c>after </c></test>")
            XCTAssertEqual(xml2, xml)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPreserveWhitespaceDecodeEncode() {
        let xml = """
                    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
                    <test>
                        <a> before</a>
                        <b></b>
                        <c>after </c>
                    </test>
                    """
        testDecodeEncode(xml: xml, options: .nodePreserveWhitespace)
    }
    
    func testCompactedEmptyElementsDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test><compacted/></test>"
        testDecodeEncode(xml: xml, options: .nodeCompactEmptyElement)
    }
    
    func testNodesOutsideRootElementDecodeEncode() {
        let xml = """
                    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
                    
                    <!-- test comment -->
                    
                    <test>
                        <a> before</a>
                        <b></b>
                        <c>after </c>
                    </test>
                    """
        testDecodeEncode(xml: xml, options: .nodePreserveWhitespace)
    }

    static var allTests : [(String, (XMLTests) -> () throws -> Void)] {
        return [
            ("testAddChild", testAddChild),
            ("testAddRemoveChild", testAddRemoveChild),
            ("testAttributeAdd", testAttributeAdd),
            ("testAttributeReplace", testAttributeReplace),
            ("testNamespaceAdd", testNamespaceAdd),
            ("testNamespaceReplace", testNamespaceReplace),
            ("testNullNamespaceReplace", testNamespaceReplace),
            ("testAttributesDecodeEncode", testAttributesDecodeEncode),
            ("testNamespacesDecodeEncode", testNamespacesDecodeEncode),
            ("testArrayDecodeEncode", testArrayDecodeEncode),
            ("testCommentDecodeEncode", testCommentDecodeEncode),
            ("testCDATADecodeEncode", testCDATADecodeEncode),
            ("testWhitespaceDecodeEncode", testWhitespaceDecodeEncode),
            ("testPreserveWhitespaceDecodeEncode", testPreserveWhitespaceDecodeEncode),
            ("testCompactedEmptyElementsDecodeEncode", testCompactedEmptyElementsDecodeEncode),
            ("testNodesOutsideRootElementDecodeEncode", testNodesOutsideRootElementDecodeEncode)
        ]
    }
}

