//
//  XML.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/06/15
//

// Implemented to replace the XML Foundation classes. This was initially required as there is no implementation of the Foundation XMLNode classes in iOS. This is also here because the implementation of XMLNode in Linux Swift 4.2 was causing crashes. Whenever an XMLDocument was deleted all the underlying CoreFoundation objects were deleted. This meant if you still had a reference to a XMLElement from that document, while it was still valid the underlying CoreFoundation object had been deleted.

import Foundation

// I have placed everything inside a holding XML class to avoid name clashes with the Foundation version. Otherwise this class reflects the behaviour of the Foundation classes as close as possible with the exceptions of, I haven't implemented queries, DTD, also XMLNodes do not contain an object reference. Also the node creation function in XMLNode return XMLNode instead of Any.
/// Holding class for all the XML objects.
public class XML {

    /// XML node type
    public enum Kind {
        case document
        case element
        case text
        case attribute
        case namespace
        case comment
    }
    
    /// Options for parsing and outputting XML Data
    public struct Options : OptionSet {
        public let rawValue: Int
        
        /// if an XML Element has no children then output as `<element />`. Default is to output `<element></element>`
        public static let nodeCompactEmptyElement = Options(rawValue: 1 << 0)
        /// output XML as human readable
        public static let nodePrettyPrint = Options(rawValue: 1 << 4)
        /// flag that XML Node should be output as CDATA
        public static let nodeIsCDATA = Options(rawValue: 1 << 5)
        
        /// when parsing XML preserve the whitespace sections
        public static let nodePreserveWhitespace = Options(rawValue: 1 << 16)
        /// when parsing XML preserve the CDATA text elements
        public static let nodePreserveCDATA = Options(rawValue: 1 << 18)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    /// Base class for all types of XML.Node
    public class Node {

        /// Name of XML node
        public var name : String?
        /// String value associated with XMLNode
        public var stringValue : String?
        /// Defines the type of XML node
        public let kind : Kind
        /// Children XML Nodes attached to this XML Node
        public fileprivate(set) var children : [XML.Node]?
        /// The parent XML Node (could be the XML Element or XML Document that owns this node)
        public fileprivate(set) weak var parent : XML.Node?
        /// Options applied to XMLNode
        fileprivate var options : Options

        /// Initialize an XML Node with a type
        init(kind: Kind, options: Options = []) {
            self.kind = kind
            self.options = options
            self.children = nil
            self.parent = nil
        }

        fileprivate init(_ kind: Kind, name: String? = nil, stringValue: String? = nil, options: Options = []) {
            self.kind = kind
            self.name = name
            self.options = options
            self.stringValue = stringValue
            self.children = nil
            self.parent = nil
        }

        /// Create XML document node
        public static func document() -> XML.Node {
            return XML.Document()
        }

        /// Create XML element node
        public static func element(withName: String, stringValue: String? = nil) -> XML.Node {
            return XML.Element(name: withName, stringValue: stringValue)
        }

        /// Create raw text node
        public static func text(stringValue: String) -> XML.Node {
            return XML.Node(.text, stringValue: stringValue)
        }

        /// Create XML attribute node
        public static func attribute(withName: String, stringValue: String) -> XML.Node {
            return XML.Node(.attribute, name: withName, stringValue: stringValue)
        }

        /// Create XML namespace node
        public static func namespace(withName: String? = nil, stringValue: String) -> XML.Node {
            return XML.Node(.namespace, name: withName, stringValue: stringValue)
        }

        /// Create XML comment node
        public static func comment(stringValue: String) -> XML.Node {
            return XML.Node(.comment, stringValue: stringValue)
        }

        /// Return the child node at index
        private func child(at index: Int) -> XML.Node? {
            return children?[index]
        }

        /// Return number of children nodes
        public var childCount : Int { get {return children?.count ?? 0}}

        /// Detach XML node from its parent
        public func detach() {
            parent?.detach(child:self)
            parent = nil
        }

        /// Detach child XML Node from this Node
        fileprivate func detach(child: XML.Node) {
            children?.removeAll(where: {$0 === child})
        }

        /// Return children XML Nodes of a specific kind
        public func children(of kind: Kind) -> [XML.Node]? {
            return children?.compactMap { $0.kind == kind ? $0 : nil }
        }

        private static let xmlEncodedCharacters : [String.Element: String] = [
            "\"": "&quot;",
            "&": "&amp;",
            "'": "&apos;",
            "<": "&lt;",
            ">": "&gt;",
        ]
        /// encode text with XML markup
        private static func xmlEncode(string: String) -> String {
            var newString = ""
            for c in string {
                if let replacement = XML.Node.xmlEncodedCharacters[c] {
                    newString.append(contentsOf:replacement)
                } else {
                    newString.append(c)
                }
            }
            return newString
        }

        /// Output formatted XML as a String
        public var xmlString : String {
            return xmlString(options: [])
        }

        /// Output formatted XML as a String with the supplied OptionSet
        public func xmlString(options: Options) -> String {
            switch kind {
            case .text:
                if let stringValue = stringValue {
                    if self.options.contains(.nodeIsCDATA) {
                        return "<![CDATA[\(stringValue)]]>"
                    } else {
                        return XML.Node.xmlEncode(string: stringValue)
                    }
                }
                return ""
            case .attribute:
                if let name = name {
                    return "\(name)=\"\(stringValue ?? "")\""
                } else {
                    return ""
                }
            case .comment:
                if let stringValue = stringValue {
                    return "<!--\(stringValue)-->"
                } else {
                    return ""
                }
            case .namespace:
                var string = "xmlns"
                if let name = name, name != "" {
                    string += ":\(name)"
                }
                string += "=\"\(stringValue ?? "")\""
                return string
            default:
                return ""
            }
        }
    }

    /// XML Node that has XML Children nodes
    public class ContainerNode : XML.Node {
        /// Add a child node to the XML element
        public func addChild(_ node: XML.Node) {
            assert(node.kind != .namespace && node.kind != .attribute && node.kind != .document)
            if children == nil {
                children = [node]
            } else {
                children!.append(node)
            }
            node.parent = self
        }
        
        /// Insert a child node at position in the list of children nodes
        public func insertChild(node: XML.Node, at index: Int) {
            assert(node.kind != .namespace && node.kind != .attribute && node.kind != .document)
            children?.insert(node, at: index)
            node.parent = self
        }
        
        /// Set this elements children nodes
        public func setChildren(_ children: [XML.Node]?) {
            for child in self.children ?? [] {
                child.parent = nil
            }
            self.children = children
            for child in self.children ?? [] {
                assert(child.kind != .namespace && child.kind != .attribute && child.kind != .document)
                child.parent = self
            }
        }
    }
    
    /// XML Document class
    public class Document : XML.ContainerNode {
        /// XML version. If not set defaults to 1.0
        public var version : String?
        /// XML character encoding. If not set defaults to UTF-8
        public var characterEncoding : String?

        /// Initialize an XML Document
        public init() {
            super.init(.document)
        }

        /// Initialise with a single root element
        public init(rootElement: XML.Element) {
            super.init(.document)
            setRootElement(rootElement)
        }

        /// Initialise with a block of XML data
        public init(data: Data, options: Options = []) throws {
            super.init(.document)
            let parser = XMLParser(data: data)
            let parserDelegate = ParserDelegate(parentNode: self, options: options)
            parser.delegate = parserDelegate
            if !parser.parse() {
                if let error = parserDelegate.error {
                    throw error
                }
            }
        }

        /// Initialise with a string containing XML data
        convenience public init(xmlString: String, options: Options = []) throws {
            let data = xmlString.data(using: .utf8)!
            try self.init(data: data, options: options)
        }

        /// Set the root element of the document
        public func setRootElement(_ rootElement: XML.Element) {
            for child in self.children ?? [] {
                child.parent = nil
            }
            children = [rootElement]
        }

        /// Return the root element
        public func rootElement() -> XML.Element? {
            return children(of:.element)?.first as? XML.Element
        }

        /// Output formatted XML as a String
        override public func xmlString(options: Options) -> String {
            var string = "<?xml version=\"\(version ?? "1.0")\" encoding=\"\(characterEncoding ?? "UTF-8")\"?>"
            if let children = children {
                for node in children {
                    string += node.xmlString(options: options)
                }
            }
            return string
        }

        /// Output formatted XML as Data
        public var xmlData : Data { return xmlData(options: [])}

        /// Output formatted XML as Data
        public func xmlData(options: Options) -> Data {
            return xmlString(options:options).data(using: .utf8) ?? Data()
        }
    }

    /// XML Element class
    public class Element : XML.ContainerNode {

        /// array of attributes attached to XML ELement
        public fileprivate(set) var attributes : [XML.Node]?
        /// array of namespaces attached to XML Element
        public fileprivate(set) var namespaces : [XML.Node]?

        /// Initialize XML Element with name and text it contains. The text is stored as a child text node
        public init(name: String, stringValue: String? = nil) {
            super.init(.element, name: name)
            self.stringValue = stringValue
        }

        /// Initialise XML Element from XML data
        public init(xmlData: Data, options: Options = []) throws {
            super.init(.element)
            let parser = XMLParser(data: xmlData)
            let parserDelegate = ParserDelegate(options: options)
            parser.delegate = parserDelegate
            if !parser.parse() {
                if let error = parserDelegate.error {
                    throw error
                }
            } else if let rootElement = parserDelegate.rootElement {
                // copy contents of rootElement
                self.setChildren(rootElement.children)
                self.setAttributes(rootElement.attributes)
                self.setNamespaces(rootElement.namespaces)
                self.name = rootElement.name
            } else {
                throw ParsingError.emptyFile
            }
        }

        /// Initialise XML Element from string containing XML
        convenience public init(xmlString: String, options: Options = []) throws {
            let data = xmlString.data(using: .utf8)!
            try self.init(xmlData: data, options: options)
        }

        /// Return children XML elements with a given name
        public func elements(forName: String) -> [XML.Element] {
            return children?.compactMap {
                if let element = $0 as? XML.Element, element.name == forName {
                    return element
                }
                return nil
                } ?? []
        }

        /// Return child text nodes all concatenated together
        public override var stringValue : String? {
            get {
                let textNodes = children(of:.text)
                let text = textNodes?.reduce("", { return $0 + ($1.stringValue ?? "")}) ?? ""
                return text
            }
            set(value) {
                children?.removeAll {$0.kind == .text}
                if let value = value {
                    addChild(XML.Node(.text, stringValue: value))
                }
            }
        }

        /// Return attribute attached to element with a given name
        public func attribute(forName: String) -> XML.Node? {
            return attributes?.first {
                if $0.name == forName {
                    return true
                }
                return false
            }
        }

        /// Add an attribute to an element. If one with this name already exists it is replaced
        public func addAttribute(_ node : XML.Node) {
            assert(node.kind == .attribute)
            if let name = node.name, let attributeNode = attribute(forName: name) {
                attributeNode.detach()
            }
            if attributes == nil {
                attributes = [node]
            } else {
                attributes!.append(node)
            }
            node.parent = self
        }

        /// Set this elements attribute nodes
        public func setAttributes(_ attributes: [XML.Node]?) {
            for attribute in self.attributes ?? [] {
                attribute.parent = nil
            }
            self.attributes = attributes
            for attribute in self.attributes ?? [] {
                assert(attribute.kind == .attribute)
                attribute.parent = self
            }
        }

        /// Return namespace attached to element with a given name
        public func namespace(forName: String?) -> XML.Node? {
            return namespaces?.first {
                if $0.name == forName {
                    return true
                }
                return false
            }
        }

        /// Add a namespace to an element. If one with this name already exists it is replaced
        public func addNamespace(_ node : XML.Node) {
            assert(node.kind == .namespace)
            if let attributeNode = namespace(forName: node.name) {
                attributeNode.detach()
            }
            if namespaces == nil {
                namespaces = [node]
            } else {
                namespaces!.append(node)
            }
            node.parent = self
        }

        /// Set this elements namespace nodes
        public func setNamespaces(_ namespaces: [XML.Node]?) {
            for namespace in self.namespaces ?? [] {
                namespace.parent = nil
            }
            self.namespaces = namespaces
            for namespace in self.namespaces ?? [] {
                assert(namespace.kind == .namespace)
                namespace.parent = self
            }
        }

        /// Detach child XML Node from this element
        fileprivate override func detach(child: XML.Node) {
            switch child.kind {
            case .attribute:
                attributes?.removeAll(where: {$0 === child})
            case .namespace:
                namespaces?.removeAll(where: {$0 === child})
            default:
                super.detach(child: child)
            }
        }

        /// Return formatted XML
        override public func xmlString(options: Options) -> String {
            let combinedOptions = options.union(self.options)
            let children = self.children ?? []
            var string = ""
            
            string += "<\(name!)"
            string += namespaces?.map({" "+$0.xmlString(options: options)}).joined(separator:"") ?? ""
            string += attributes?.map({" "+$0.xmlString(options: options)}).joined(separator:"") ?? ""
            
            if combinedOptions.contains(.nodeCompactEmptyElement) && children.count == 0 {
                string += "/>"
            } else {
                string += ">"
                for node in children {
                    string += node.xmlString(options: options)
                }
                string += "</\(name!)>"
            }
            return string
        }
    }

    /// XML parsing errors
    enum ParsingError : Error {
        case emptyFile

        var localizedDescription: String {
            switch self {
            case .emptyFile:
                return "File contained nothing"
            }
        }
    }

    /// parser delegate used in XML parsing
    fileprivate class ParserDelegate : NSObject, XMLParserDelegate {

        var options : Options
        var rootElement : XML.Element?
        var currentNode : XML.ContainerNode?
        var lineNumber : Int
        var error : Error?

        init(parentNode : ContainerNode? = nil, options: Options = []) {
            self.options = options
            self.currentNode = parentNode
            self.rootElement = nil
            self.lineNumber = 1
            super.init()
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            whitespaceOutsideRootElement(parser)

            let element = XML.Element(name: elementName)
            for attribute in attributeDict {
                element.addAttribute(XML.Node(.attribute, name: attribute.key, stringValue: attribute.value))
            }
            if rootElement ==  nil {
                rootElement = element
            }
            currentNode?.addChild(element)
            currentNode = element
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            currentNode = currentNode?.parent as? XML.Element
        }

        func parser(_ parser: XMLParser, foundCharacters: String) {
            // if string with white space removed still has characters, or we are preserving whitespace, add text node
            if options.contains(.nodePreserveWhitespace) || foundCharacters.components(separatedBy: .whitespaces).joined().count > 0 {
                currentNode?.addChild(XML.Node.text(stringValue: foundCharacters))
            }
        }

        func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String) {
            if options.contains(.nodePreserveWhitespace) {
                currentNode?.addChild(XML.Node.text(stringValue: whitespaceString))
            }
        }
        
        func parser(_ parser: XMLParser, foundComment comment: String) {
            whitespaceOutsideRootElement(parser)
            currentNode?.addChild(XML.Node.comment(stringValue: comment))
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            let cdata = XML.Node.text(stringValue: String(data: CDATABlock, encoding: .utf8)!)
            if options.contains(.nodePreserveCDATA) {
                cdata.options.insert(.nodeIsCDATA)
            }
            currentNode?.addChild(cdata)
        }

        func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
            error = parseError
        }

        func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
            error = validationError
        }
        
        // if preserving whitespace. This is a bit of a hack as the parser doesn't return whitespace outside of the rootelement
        private func whitespaceOutsideRootElement(_ parser: XMLParser) {
            if options.contains(.nodePreserveWhitespace) && rootElement == nil && currentNode != nil {
                var whitespace = ""
                for _ in lineNumber..<parser.lineNumber {
                    whitespace += "\n"
                }
                if whitespace != "" {
                    currentNode?.addChild(Node.text(stringValue: whitespace))
                }
                self.lineNumber = parser.lineNumber
            }
        }
    }

}

extension XML.Node : CustomStringConvertible, CustomDebugStringConvertible {
    /// CustomStringConvertible protocol
    public var description: String {return xmlString}
    /// CustomDebugStringConvertible protocol
    public var debugDescription: String {return xmlString}
}
