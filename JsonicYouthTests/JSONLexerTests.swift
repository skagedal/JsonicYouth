//
//  Created by Simon Kågedal Reimer on 2017-01-11.
//  Copyright © 2017 SKR. All rights reserved.
//

import XCTest
import JsonicYouth

class JSONLexerTests: XCTestCase {
    func testWhitespace() {
        let lexer = JSONLexer(string: " ")
        XCTAssertEqual(try lexer.next()?.token, Token.whitespace(" "))
        XCTAssertEqual(try lexer.next()?.token, nil)
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
        XCTAssertEqual(try lexer.next()?.token, Token.whitespace("\t"))
        XCTAssertEqual(try lexer.next()?.token, Optional.some(Token.string("hello")))
        XCTAssertEqual(try lexer.next()?.token, Optional.some(Token.whitespace("\n")))
        XCTAssertEqual(try lexer.next()?.token, nil)
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
    
    func testLexerPosition() {
        let lexer = JSONLexer(string: "\t\n\"foo\"\n{}null")
        do {
            var t = try lexer.next()!
            XCTAssertEqual(t.token, Token.whitespace("\t\n"))
            XCTAssertEqual(t.position.rows, 0)
            XCTAssertEqual(t.position.totalScalars, 0)
            XCTAssertEqual(t.position.scalarsInRow, 0)
            t = try lexer.next()!
            XCTAssertEqual(t.token, Token.string("foo"))
            XCTAssertEqual(t.position.rows, 1)
            XCTAssertEqual(t.position.totalScalars, 2)
            XCTAssertEqual(t.position.scalarsInRow, 0)
            t = try lexer.next()!
            XCTAssertEqual(t.token, Token.whitespace("\n"))
            XCTAssertEqual(t.position.rows, 1)
            XCTAssertEqual(t.position.totalScalars, 7)
            XCTAssertEqual(t.position.scalarsInRow, 5)
            t = try lexer.next()!
            XCTAssertEqual(t.token, Token.leftCurlyBracket)
            XCTAssertEqual(t.position.rows, 2)
            XCTAssertEqual(t.position.totalScalars, 8)
            XCTAssertEqual(t.position.scalarsInRow, 0)
            t = try lexer.next()!
            XCTAssertEqual(t.token, Token.rightCurlyBracket)
            XCTAssertEqual(t.position.rows, 2)
            XCTAssertEqual(t.position.totalScalars, 9)
            XCTAssertEqual(t.position.scalarsInRow, 1)
            t = try lexer.next()!
            XCTAssertEqual(t.token, Token.keyword("null"))
            XCTAssertEqual(t.position.rows, 2)
            XCTAssertEqual(t.position.totalScalars, 10)
            XCTAssertEqual(t.position.scalarsInRow, 2)

            XCTAssertNil(try lexer.next())
            let lastPosition = lexer.positionOfNextToken
            XCTAssertEqual(lastPosition.rows, 2)
            // XCTAssertEqual(<#T##expression1: [T : U]##[T : U]#>, <#T##expression2: [T : U]##[T : U]#>)
        } catch {
            return XCTFail("shouldn't throw")
        }
    }
    
    // Assertion helpers
    
    func assertThat(_ string: String, scansAs tokens: [Token]) {
        let lexer = JSONLexer(string: string)
        for token in tokens {
            XCTAssertEqual(try lexer.next()?.token, token)
        }
        XCTAssertEqual(try lexer.next()?.token, nil)
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
