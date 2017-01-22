//
//  Created by Simon Kågedal Reimer on 2017-01-11.
//  Copyright © 2017 SKR. All rights reserved.
//

import XCTest
import JsonicYouth

class JSONLexerTests: XCTestCase {
    func testWhitespace() {
        let lexer = JSONLexer(string: " ")
        XCTAssertEqual(try lexer.next(), Token.whitespace(" "))
        XCTAssertEqual(try lexer.next(), nil)
    }
    
    func testStrings() {
        assertThat("\"hello\"", scansAs: [.string("hello")])
        assertThat("\"hi", failsWithUnexpectedEndAtPosition: 3)
        assertThat("\"\t", failsWithUnexpectedScalar: "\t", atPosition: 1)
        assertThat("\"\\t\\uabcd\"", scansAs: [.string("\\t\\uabcd")])
        assertThat("\"\\uax", failsWithUnexpectedScalar: "x", atPosition: 4)
    }
    
    func testWhitespacedString() {
        let lexer = JSONLexer(string: "\t\"hello\"\n")
        XCTAssertEqual(try lexer.next(), Token.whitespace("\t"))
        XCTAssertEqual(try lexer.next(), Optional.some(Token.string("hello")))
        XCTAssertEqual(try lexer.next(), Optional.some(Token.whitespace("\n")))
        XCTAssertEqual(try lexer.next(), nil)
    }
    
    func testNumbers() {
        assertThat("123", scansAs: [.number("123")])
        assertThat("5e10", scansAs: [.number("5e10")])
        assertThat("1.5,0.9,-1.3E-10", scansAs: [.number("1.5"), .comma, .number("0.9"), .comma, .number("-1.3E-10")])
        assertThat(" 123 ", scansAs: [.whitespace(" "), .number("123"), .whitespace(" ")])
        assertThat("{1.0}", scansAs: [.leftCurlyBracket, .number("1.0"), .rightCurlyBracket])
        assertThat("1.", failsWithUnexpectedEndAtPosition: 2)
        assertThat("-", failsWithUnexpectedEndAtPosition: 1)
        assertThat("5e", failsWithUnexpectedEndAtPosition: 2)
        assertThat("5e+", failsWithUnexpectedEndAtPosition: 3)
        assertThat(".10", failsWithUnexpectedScalar: ".", atPosition: 0)
        assertThat("-x", failsWithUnexpectedScalar: "x", atPosition: 1)
    }
    
    func testKeywords() {
        assertThat("truefalsenull", scansAs: [.keyword("true"), .keyword("false"), .keyword("null")])
        assertThat("fail", failsWithUnexpectedScalar: "i", atPosition: 2)
    }
    
    // Assertion helpers
    
    func assertThat(_ string: String, scansAs tokens: [Token]) {
        let lexer = JSONLexer(string: string)
        for token in tokens {
            XCTAssertEqual(try lexer.next(), token)
        }
        XCTAssertEqual(try lexer.next(), nil)
    }
    
    func assertThat(_ string: String, failsWithUnexpectedScalar scalar: UnicodeScalar, atPosition position: Int) {
        let lexer = JSONLexer(string: string)
        
        XCTAssertThrowsError(try lexer.scanAll()) { error in
            guard case JSONError.unexpectedUnicodeScalar(let errorScalar, let errorPosition) = error else {
                return XCTFail()
            }
            
            XCTAssertEqual(errorScalar, scalar)
            XCTAssertEqual(errorPosition.totalScalars, position)
        }
    }
    
    func assertThat(_ string: String, failsWithUnexpectedEndAtPosition position: Int) {
        let lexer = JSONLexer(string: string)
        
        XCTAssertThrowsError(try lexer.scanAll()) { error in
            guard case JSONError.unexpectedEndOfData(let errorPosition) = error else {
                return XCTFail()
            }
            
            XCTAssertEqual(errorPosition.totalScalars, position)
        }
    }
}

extension JSONLexer {
    func scanAll() throws {
        while let _ = try self.next() { }
    }
}
