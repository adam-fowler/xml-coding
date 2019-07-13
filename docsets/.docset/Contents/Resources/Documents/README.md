# XML Encoder
<div>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.0-brightgreen.svg" alt="Swift 5.0" />
    </a>
    <a href="https://travis-ci.org/adam-fowler/xml-encoder">
        <img src="https://travis-ci.org/adam-fowler/xml-encoder.svg?branch=master" alt="Travis Build" />
    </a>
</div>

This is a XML encoder and decoder that integrates with the Swift Codable system. It can create an XML tree from a Codable class or create Codable classes from an XML tree. The encoder uses its own XML classes which fairly closely follow the format of the XMLNode classes found in the macOS and Linux Foundation classes.

## Using the classes
The basic method for saving a XML file from a Codable class or struct is as follows
```
let xml = try XMLEncoder().encode(codable)
let xmlString = xml.xmlString
```
And to create a Codable class from xml data
```
let xmlDocument = try XML.Document(data: data)
let codable = try XMLDecoder().decode(Codable.self, from: xmlDocument.rootElement) 
```
