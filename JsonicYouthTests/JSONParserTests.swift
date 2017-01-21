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
                    JSONValue(prefixWhitespace: "", postfixWhitespace: "", element: .string("\"yo\""))
                    ])
                XCTAssertEqual(array.internalWhitespace, "")
            } else {
                XCTFail("should return an array")
            }
        } catch {
            XCTFail("shouldn't throw")
        }
    
    }
}