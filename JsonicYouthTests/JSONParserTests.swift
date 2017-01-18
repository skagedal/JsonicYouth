//
//  Created by Simon Kågedal Reimer on 2017-01-17.
//  Copyright © 2017 SKR. All rights reserved.
//

import XCTest
import JsonicYouth

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
}
