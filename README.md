# XML Encoder
![Swift](http://img.shields.io/badge/swift-5.1-brightgreen.svg)
![CI](https://github.com/adam-fowler/xml-coding/workflows/CI/badge.svg)

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
Reference documentation can be found [here](https://adam-fowler.github.io/xml-encoder/index.html).

## Encoding arrays and dictionaries
In XML the way collections are encoded can vary quite a bit. In a previous version of this library I tried to implement this inside the encoder/decoder. I have removed this code in favour of using codable property wrappers. These allow us to mark up member variables of a class with how we want them to serialize. The library comes with a series of properties wrappers to control collection serialization. There are two property wrappers `@Coding` to be used with non-optional member variables and `@OptionalCoding` to be used with optional member variables. Both property wrappers have a `CustomCoder` generic variable. This `CustomCoder` is a protocol which has two static functions `decode` and `encode`. These functions are used to provide custom encoding and decoding for an object. The library comes with `CustomCoder` classes for arrays and dictionaries. 

By default an object like the following 
```
struct Object {
    var array: [Int]
}
```
would serialize as follows
```
<Object><array>1</array><array>2</array><array>3</array><array>4</array></Object>
```
By using the `ArrayCoder` object and a `ArrayCoderProperties` object to define the element names along with the `@Coding` property wrapper
```
struct Object {
    struct MyArrayCoderProperties: ArrayCoderProperties { static let member = "member" }
    @Coder<ArrayCoder<MyArrayCoderProperties, Int>>
    var array: [Int]
}
```
it now serialize as follows
```
<Object><array><member>1</member><member>2</member><member>3</member><member>4</member></array></Object>
```
There is a typealias `DefaultArrayCoder` for the common element name "member" which reduces the verbosity of the code a little. With this the struct would look like this.
```
struct Object {
    @Coder<DefaultArrayCoder> var array: [Int]
}
```
There are similar structures for defining Dictionary encoding and decoding. Except they have three possible variables, the name of each element node, the name of the key node and the name of the value node.
