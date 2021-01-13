import XCTest
@testable import XMLCoding

final class XMLCodingTests: XCTestCase {
    
    struct Numbers : Codable {
        
        init(bool:Bool, integer:Int, float:Float, double:Double, intEnum:IntEnum) {
            self.bool = bool
            self.integer = integer
            self.float = float
            self.double = double
            self.intEnum = intEnum
            self.int8 = 4
            self.uint16 = 5
            self.int32 = 7
            self.uint64 = 90
        }
        
        enum IntEnum : Int, Codable {
            case first
            case second
            case third
        }
        let bool : Bool
        let integer : Int
        let float : Float
        let double : Double
        let intEnum : IntEnum
        let int8 : Int8
        let uint16 : UInt16
        let int32 : Int32
        let uint64 : UInt64
        
        private enum CodingKeys : String, CodingKey {
            case bool = "b"
            case integer = "i"
            case float = "s"
            case double = "d"
            case intEnum = "enum"
            case int8 = "int8"
            case uint16 = "uint16"
            case int32 = "int32"
            case uint64 = "uint64"
        }
    }
    
    struct StringShape : Codable {
        enum StringEnum : String, Codable {
            case first="first"
            case second="second"
            case third="third"
            case fourth="fourth"
        }
        let string : String
        let optionalString : String?
        let stringEnum : StringEnum
    }
    
    struct Arrays : Codable {
        let arrayOfNatives : [Int]
        let arrayOfShapes : [Numbers]
    }
    
    struct Dictionaries : Codable {
        let dictionaryOfNatives : [String:Int]
        let dictionaryOfShapes : [String:StringShape]
        
        private enum CodingKeys : String, CodingKey {
            case dictionaryOfNatives = "natives"
            case dictionaryOfShapes = "shapes"
        }
    }
    
    struct Shape : Codable {
        let numbers : Numbers
        let stringShape : StringShape
        let arrays : Arrays
        
        private enum CodingKeys : String, CodingKey {
            case numbers = "Numbers"
            case stringShape = "Strings"
            case arrays = "Arrays"
        }
    }
    
    struct ShapeWithDictionaries : Codable {
        let shape : Shape
        let dictionaries : Dictionaries
        
        private enum CodingKeys : String, CodingKey {
            case shape = "s"
            case dictionaries = "d"
        }
    }
    
    var testShape : Shape {
        return Shape(numbers: Numbers(bool:true, integer: 45, float: 3.4, double: 7.89234, intEnum: .second),
                     stringShape: StringShape(string: "String1", optionalString: "String2", stringEnum: .third),
                     arrays: Arrays(arrayOfNatives: [34,1,4098], arrayOfShapes: [Numbers(bool:false, integer: 1, float: 1.2, double: 1.4, intEnum: .first), Numbers(bool:true, integer: 3, float: 2.01, double: 1.01, intEnum: .third)]))
    }
    
    var testShapeWithDictionaries : ShapeWithDictionaries {
        return ShapeWithDictionaries(shape: testShape, dictionaries: Dictionaries(dictionaryOfNatives: ["first":1, "second":2, "third":3],
                                                                                  dictionaryOfShapes: ["strings":StringShape(string:"one", optionalString: "two", stringEnum: .third),
                                                                                                       "strings2":StringShape(string:"cat", optionalString: nil, stringEnum: .fourth)]))
    }
    
    /// helper test function to use throughout all the decode/encode tests
    func testDecode<T : Codable>(type: T.Type, xml: String) -> T? {
        do {
            let xmlDocument = try XML.Document(data: xml.data(using: .utf8)!)
            let rootElement = xmlDocument.rootElement()
            XCTAssertNotNil(rootElement)
            return try XMLDecoder().decode(T.self, from: rootElement!)
            //let xmlElement = try XMLEncoder().encode(instance)
            //XCTAssertEqual(xml, xmlElement.xmlString)
        } catch {
            XCTFail(error.localizedDescription)
        }
        return nil
    }
    
    /// helper test function to use throughout all the decode/encode tests
    func testDecodeEncode<T : Codable>(type: T.Type, xml: String) {
        do {
            let xmlDocument = try XML.Document(data: xml.data(using: .utf8)!)
            let rootElement = xmlDocument.rootElement()
            XCTAssertNotNil(rootElement)
            let instance = try XMLDecoder().decode(T.self, from: rootElement!)
            let xmlElement = try XMLEncoder().encode(instance)
            XCTAssertEqual(xml, xmlElement.xmlString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSimpleStructureDecodeEncode() {
        struct Test : Codable {
            let a : Int
            let b : String
        }
        let xml = "<Test><a>5</a><b>Hello</b></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testContainingStructureDecodeEncode() {
        struct Test : Codable {
            let a : Int
            let b : String
        }
        struct Test2 : Codable {
            let t : Test
        }
        let xml = "<Test2><t><a>5</a><b>Hello</b></t></Test2>"
        testDecodeEncode(type: Test2.self, xml: xml)
    }
    
    func testEnumDecodeEncode() {
        struct Test : Codable {
            enum TestEnum : String, Codable {
                case first = "First"
                case second = "Second"
            }
            let a : TestEnum
        }
        let xml = "<Test><a>Second</a></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testArrayDecodeEncode() {
        struct Test : Codable {
            let a : [Int]
        }
        let xml = "<Test><a>5</a><a>7</a></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testArrayOfStructuresDecodeEncode() {
        struct Test2 : Codable {
            let b : String
        }
        struct Test : Codable {
            let a : [Test2]
        }
        let xml = "<Test><a><b>Hello</b></a><a><b>Goodbye</b></a></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testDictionaryDecodeEncode() {
        struct Test : Codable {
            let a : [String:Int]
        }
        let xml = "<Test><a><first>1</first></a></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testDateDecodeEncode() {
        struct Test : Codable {
            let date : Date
        }
        let xml = "<Test><date>24876876234.5</date></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testDataDecodeEncode() {
        struct Test : Codable {
            let data : Data
        }
        let base64 = "Hello, world".data(using:.utf8)!.base64EncodedString()
        let xml = "<Test><data>\(base64)</data></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testUrlDecodeEncode() {
        struct Test : Codable {
            let url : URL
        }
        let xml = "<Test><url>https://docs.aws.amazon.com/</url></Test>"
        testDecodeEncode(type: Test.self, xml: xml)
    }
    
    func testSerializeToXML() {
        let shape = testShape
        let node = try! XMLEncoder().encode(shape)
        
        let xml = node.xmlString
        let xmlToTest = "<Shape><Numbers><b>true</b><i>45</i><s>3.4</s><d>7.89234</d><enum>1</enum><int8>4</int8><uint16>5</uint16><int32>7</int32><uint64>90</uint64></Numbers><Strings><string>String1</string><optionalString>String2</optionalString><stringEnum>third</stringEnum></Strings><Arrays><arrayOfNatives>34</arrayOfNatives><arrayOfNatives>1</arrayOfNatives><arrayOfNatives>4098</arrayOfNatives><arrayOfShapes><b>false</b><i>1</i><s>1.2</s><d>1.4</d><enum>0</enum><int8>4</int8><uint16>5</uint16><int32>7</int32><uint64>90</uint64></arrayOfShapes><arrayOfShapes><b>true</b><i>3</i><s>2.01</s><d>1.01</d><enum>2</enum><int8>4</int8><uint16>5</uint16><int32>7</int32><uint64>90</uint64></arrayOfShapes></Arrays></Shape>"
        
        XCTAssertEqual(xmlToTest, xml)
    }
    
    func testDecodeFail() {
        let missingNative = "<Numbers><b>true</b><i>45</i><s>3.4</s><d>7.89234</d><enum>1</enum><int8>4</int8><uint16>5</uint16><int32>7</int32></Numbers>"
        let missingEnum = "<Numbers><b>true</b><i>45</i><s>3.4</s><d>7.89234</d></Numbers>"
        let wrongEnum = "<Strings><string>String1</string><optionalString>String2</optionalString><stringEnum>twenty</stringEnum></Strings>"
        let missingShape = "<Shape><Numbers><b>true</b><i>45</i><s>3.4</s><d>7.89234</d><enum>1</enum><int8>4</int8><uint16>5</uint16><int32>7</int32><uint64>90</uint64></Numbers><Strings><string>String1</string><optionalString>String2</optionalString><stringEnum>third</stringEnum></Strings></Shape>"
        let stringNotShape = "<Dictionaries><natives></natives><shapes><first>test</first></shapes></Dictionaries>"
        let notANumber = "<Dictionaries><natives><test>notANumber</test></natives><shapes></shapes></Dictionaries>"
        
        do {
            var xmlDocument = try XML.Document(data: missingNative.data(using: .utf8)!)
            XCTAssertNotNil(xmlDocument.rootElement())
            let result = try? XMLDecoder().decode(Numbers.self, from: xmlDocument.rootElement()!)
            XCTAssertNil(result)
            
            xmlDocument = try XML.Document(data: missingEnum.data(using: .utf8)!)
            XCTAssertNotNil(xmlDocument.rootElement())
            let result2 = try? XMLDecoder().decode(Numbers.self, from: xmlDocument.rootElement()!)
            XCTAssertNil(result2)
            
            xmlDocument = try XML.Document(data: wrongEnum.data(using: .utf8)!)
            XCTAssertNotNil(xmlDocument.rootElement())
            let result3 = try? XMLDecoder().decode(StringShape.self, from: xmlDocument.rootElement()!)
            XCTAssertNil(result3)
            
            xmlDocument = try XML.Document(data: missingShape.data(using: .utf8)!)
            XCTAssertNotNil(xmlDocument.rootElement())
            let result4 = try? XMLDecoder().decode(Shape.self, from: xmlDocument.rootElement()!)
            XCTAssertNil(result4)
            
            xmlDocument = try XML.Document(data: stringNotShape.data(using: .utf8)!)
            XCTAssertNotNil(xmlDocument.rootElement())
            let result5 = try? XMLDecoder().decode(Dictionaries.self, from: xmlDocument.rootElement()!)
            XCTAssertNil(result5)
            
            xmlDocument = try XML.Document(data: notANumber.data(using: .utf8)!)
            XCTAssertNotNil(xmlDocument.rootElement())
            let result6 = try? XMLDecoder().decode(Dictionaries.self, from: xmlDocument.rootElement()!)
            XCTAssertNil(result6)
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testNestedContainers() throws {
        struct Object: Codable {
            let firstName: String
            let surname: String
            let age: Int
            let street: String
            let city: String

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.age = try container.decode(Int.self, forKey: .age)
                let nameContainer = try container.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
                self.firstName = try nameContainer.decode(String.self, forKey: .firstName)
                self.surname = try nameContainer.decode(String.self, forKey: .surname)
                let addressContainer = try container.nestedContainer(keyedBy: AddressCodingKeys.self, forKey: .address)
                self.street = try addressContainer.decode(String.self, forKey: .street)
                self.city = try addressContainer.decode(String.self, forKey: .city)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(age, forKey: .age)
                var nameContainer = container.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
                try nameContainer.encode(firstName, forKey: .firstName)
                try nameContainer.encode(surname, forKey: .surname)
                var addressContainer = container.nestedContainer(keyedBy: AddressCodingKeys.self, forKey: .address)
                try addressContainer.encode(street, forKey: .street)
                try addressContainer.encode(city, forKey: .city)
            }

            private enum CodingKeys: String, CodingKey {
                case name = "name"
                case age = "age"
                case address = "address"
            }

            private enum NameCodingKeys: String, CodingKey {
                case firstName = "firstName"
                case surname = "surname"
            }
            private enum AddressCodingKeys: String, CodingKey {
                case street = "street"
                case city = "city"
            }
        }
        let xmldata = "<Object><age>65</age><name><firstName>John</firstName><surname>Smith</surname></name><address><street>Cambridge Street</street><city>Oxford</city></address></Object>"
        testDecodeEncode(type: Object.self, xml: xmldata)
    }
    
    func testDecodeExpandedContainers() {
        struct Shape : Codable {
            @CustomCoding<DefaultArrayCoder> var array : [Int]
            @CustomCoding<DefaultDictionaryCoder> var dictionary : [String: Int]
        }
        let xmldata = "<Shape><array><member>3</member><member>2</member><member>1</member></array><dictionary><entry><key>one</key><value>1</value></entry><entry><key>two</key><value>2</value></entry><entry><key>three</key><value>3</value></entry></dictionary></Shape>"
        if let shape = testDecode(type: Shape.self, xml: xmldata) {
            XCTAssertEqual(shape.array[0], 3)
            XCTAssertEqual(shape.dictionary["two"], 2)
        }
    }
    
    func testArrayEncodingDecodeEncode() {
        struct Shape : Codable {
            @CustomCoding<DefaultArrayCoder> var array : [Int]
        }
        let xmldata = "<Shape><array><member>3</member><member>2</member><member>1</member></array></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
    
    func testOptionalArrayDecodeEncode() {
        struct Shape : Codable {
            @OptionalCustomCoding<DefaultArrayCoder> var array : [Int]?
        }
        let xmldata = "<Shape><array><member>3</member><member>2</member><member>1</member></array></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
        let xmldata2 = "<Shape></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata2)
    }
    
    func testArrayOfStructuresEncodingDecodeEncode() {
        struct Shape2 : Codable {
            let value : String
        }
        struct Shape : Codable {
            @CustomCoding<DefaultArrayCoder> var array : [Shape2]
        }
        let xmldata = "<Shape><array><member><value>test</value></member><member><value>test2</value></member><member><value>test3</value></member></array></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
    
    func testDictionaryEncodingDecodeEncode() {
        struct Shape : Codable {
            struct _DEncodingProperties: DictionaryCoderProperties {
                static let entry: String? = "item"; static let key = "key"; static let value = "value"
            }
            @CustomCoding<DictionaryCoder<_DEncodingProperties, String, Int>>
            var d : [String:Int]
        }
        let xmldata = "<Shape><d><item><key>member</key><value>4</value></item></d></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
    
    func testDictionaryOfStructuresEncodingDecodeEncode() {
        struct Shape2 : Codable {
            let float : Float
        }
        struct Shape : Codable {
            struct _DEncodingProperties: DictionaryCoderProperties {
                static let entry: String? = "item"; static let key = "key"; static let value = "value"
            }
            @CustomCoding<DictionaryCoder<_DEncodingProperties, String, Shape2>>
            var d : [String: Shape2]
        }
        let xmldata = "<Shape><d><item><key>member</key><value><float>1.5</float></value></item></d></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
    
    func testFlatDictionaryEncodingDecodeEncode() {
        struct Shape : Codable {
            struct _DEncodingProperties: DictionaryCoderProperties {
                static let entry: String? = nil; static let key = "key"; static let value = "value"
            }
            @CustomCoding<DictionaryCoder<_DEncodingProperties, String, Int>>
            var d : [String:Int]
        }
        let xmldata = "<Shape><d><key>member</key><value>4</value></d></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
    
    func testEnumDictionaryEncodingDecodeEncode() {
        enum KeyEnum : String, Codable {
            case member = "member"
            case member2 = "member2"
        }
        struct Shape : Codable {
            @CustomCoding<DefaultDictionaryCoder> var d : [KeyEnum:Int]
        }
        let xmldata = "<Shape><d><entry><key>member</key><value>4</value></entry></d></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
    
    func testEnumFlatDictionaryEncodingDecodeEncode() {
        enum KeyEnum : String, Codable {
            case member = "member"
            case member2 = "member2"
        }
        struct Shape : Codable {
            struct _DEncodingProperties: DictionaryCoderProperties {
                static let entry: String? = nil; static let key = "key"; static let value = "value"
            }
            @CustomCoding<DictionaryCoder<_DEncodingProperties, KeyEnum, Int>>
            var d : [KeyEnum:Int]
        }
        let xmldata = "<Shape><d><key>member</key><value>4</value></d></Shape>"
        testDecodeEncode(type: Shape.self, xml: xmldata)
    }
}
