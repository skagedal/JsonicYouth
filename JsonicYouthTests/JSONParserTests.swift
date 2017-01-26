//
//  Created by Simon Kågedal Reimer on 2017-01-17.
//  Copyright © 2017 SKR. All rights reserved.
//

import XCTest
@testable import JsonicYouth

class JSONParserTests: XCTestCase {
    func testNull() {
        do {
            let j = try JSONParser(string: "null").parse()
            XCTAssertEqual(j.element, JSONElement.null)
        } catch {
            XCTFail("shouldn't throw")
        }
    }
    
    func testTrue() {
        do {
            let j = try JSONParser(string: " true\n").parse()
            XCTAssertEqual(j.element, JSONElement.bool(true))
            XCTAssertEqual(j.prefixWhitespace, " ")
            XCTAssertEqual(j.postfixWhitespace, "\n")
        } catch {
            XCTFail("shouldn't throw")
        }
    }
    
    func testArray() {
        do {
            let j = try JSONParser(string: "[]").parse()
            if case let JSONElement.array(array) = j.element {
                XCTAssertEqual(array.values, [])
                XCTAssertEqual(array.internalWhitespace, "")
            } else {
                XCTFail("should return an array")
            }
        } catch {
            XCTFail("shouldn't throw")
        }

        do {
            let j = try JSONParser(string: "[true,false,null,1,\"yo\"]").parse()
            if case let JSONElement.array(array) = j.element {
                XCTAssertEqual(array.values, [
                    JSONValue(prefixWhitespace: "", postfixWhitespace: "", element: .bool(true)),
                    JSONValue(prefixWhitespace: "", postfixWhitespace: "", element: .bool(false)),
                    JSONValue(prefixWhitespace: "", postfixWhitespace: "", element: .null),
                    JSONValue(prefixWhitespace: "", postfixWhitespace: "", element: .number("1")),
                    JSONValue(prefixWhitespace: "", postfixWhitespace: "", element: .string("yo"))
                    ])
                XCTAssertEqual(array.internalWhitespace, "")
            } else {
                XCTFail("should return an array")
            }
        } catch {
            XCTFail("shouldn't throw")
        }
    
    }
    
    func testObject() {
        do {
            let j = try JSONParser(string: "{\"foo\":true,\"bar\":false}").parse()
            guard case let JSONElement.object(object) = j.element else {
                return XCTFail("should return an object")
            }
            XCTAssertEqual(object.keyValues.count, 2)
            let foo = object.keyValues[0]
            XCTAssertEqual(foo.key.key, "foo")
            XCTAssertEqual(foo.value.element, .bool(true))
            let bar = object.keyValues[1]
            XCTAssertEqual(bar.key.key, "bar")
            XCTAssertEqual(bar.value.element, .bool(false))
            
        } catch {
            XCTFail("shouldn't throw")
        }
    }
    
    func testStringParser() {
        do {
            let s = try JSONParser(string: "\"\"").parse()
            if let string = s.element.stringValue {
                XCTAssertEqual(string, "")
            } else {
                return XCTFail("should return a string element")
            }
            
            let s2 = try JSONParser(string: "\"hej\\t\\n\\uD83D\\uDC98\"").parse()
            if let string = s2.element.stringValue {
                XCTAssertEqual(string, "hej\t\n💘")
            } else {
                return XCTFail("should return a string element")
            }
            
        } catch {
            XCTFail("shouldn't throw")
        }
    }
    
    func testWhitespacePreservation() {
        let j1 = " [  { \"hello\" : 0,   \"asdf\":  null},   false ]  "
        XCTAssertEqual(j1, String(describing: try JSONParser(string: j1).parse()))
    }
}
