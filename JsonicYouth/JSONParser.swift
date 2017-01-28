//
//  Copyright © 2017 Simon Kågedal Reimer. MIT license; see LICENSE file.
//

public enum TemporaryError: Error {
    case notImplemented
}

// MARK: Parse tree

public struct JSONValue {
    public let prefixWhitespace: String
    public let postfixWhitespace: String
    public let element: JSONElement
}

public enum JSONElement {
    case object(JSONObject)
    case array(JSONArray)
    case number(String)
    case string(String)
    case bool(Bool)
    case null
}

public struct JSONObject {
    public let keyValues: [JSONKeyValue]
    public let internalWhitespace: String
}

public struct JSONArray {
    public let values: [JSONValue]
    public let internalWhitespace: String
}

public struct JSONKeyValue {
    public let key: JSONKey
    public let value: JSONValue
}

public struct JSONKey {
    public let prefixWhitespace: String
    public let postfixWhitespace: String
    public let key: String
}

// MARK: Equatable

extension JSONValue: Equatable {
    public static func ==(lhs: JSONValue, rhs: JSONValue) -> Bool {
        return lhs.prefixWhitespace == rhs.prefixWhitespace &&
            lhs.postfixWhitespace == rhs.postfixWhitespace &&
            lhs.element == rhs.element
    }
}

extension JSONElement: Equatable {
    public static func ==(lhs: JSONElement, rhs: JSONElement) -> Bool {
        switch (lhs, rhs) {
        case let (.object(a), .object(b)):
            return a == b
            
        case let (.array(a), .array(b)):
            return a == b
            
        case let (.number(a), .number(b)):
            return a == b
            
        case let (.string(a), .string(b)):
            return a == b
            
        case let (.bool(a), .bool(b)):
            return a == b
            
        case (.null, .null):
            return true
            
        case (.object(_), _), (.array(_), _), (.number(_), _), (.string(_), _), (.bool(_), _), (.null, _):
            return false
        }
    }
}

extension JSONKey: Equatable {
    public static func ==(lhs: JSONKey, rhs: JSONKey) -> Bool {
        return lhs.prefixWhitespace == rhs.prefixWhitespace &&
            lhs.postfixWhitespace == rhs.postfixWhitespace &&
            lhs.key == rhs.key
    }
}

extension JSONKeyValue: Equatable {
    public static func ==(lhs: JSONKeyValue, rhs: JSONKeyValue) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}

extension JSONObject: Equatable {
    public static func ==(lhs: JSONObject, rhs: JSONObject) -> Bool {
        return lhs.internalWhitespace == rhs.internalWhitespace &&
            lhs.keyValues == rhs.keyValues
    }
}

extension JSONArray: Equatable {
    public static func ==(lhs: JSONArray, rhs: JSONArray) -> Bool {
        return lhs.internalWhitespace == rhs.internalWhitespace &&
            lhs.values == rhs.values
    }
}

// MARK: Parser

public class JSONParser {
    public init(lexer: JSONLexer) {
        self.lexer = PeekableLexer(lexer)
    }

    public convenience init(string: String) {
        self.init(lexer: JSONLexer(string: string))
    }
    
    public func parse() throws -> JSONValue {
        let value = try parseValue()
        if let token = try lexer.next() {
            throw JSONError.unexpectedToken(token.token, token.position)
        }
        return value
    }

    func parseValue() throws -> JSONValue {
        let prefixWhitespace = try lexer.takeWhitespace()
        let element = try parseElement()
        let postfixWhitespace = try lexer.takeWhitespace()
        return JSONValue(prefixWhitespace: prefixWhitespace,
                         postfixWhitespace: postfixWhitespace,
                         element: element)
    }
    
    func parseElement() throws -> JSONElement {
        let token = try lexer.forceNext()
        
        switch token.token {
        case .string(let stringValue):
            return .string(stringValue)
            
        case .number(let stringValue):
            return .number(stringValue)
            
        case .keyword("true"):
            return .bool(true)
            
        case .keyword("false"):
            return .bool(false)
            
        case .keyword("null"):
            return .null
            
        case .leftSquareBracket:
            return .array(try parseArray())
        
        case .leftCurlyBracket:
            return .object(try parseObject())
            
        default:
            throw JSONError.unexpectedToken(token.token, token.position)
        }
    }
    
    func parseArray() throws -> JSONArray {
        let internalWhitespace = try lexer.takeWhitespace()
        if try lexer.peek()?.token == .rightSquareBracket {
            let _ = try lexer.next()
            return JSONArray(values: [], internalWhitespace: internalWhitespace)
        }

        var values: [JSONValue] = []
        var token: PositionedToken
        repeat {
            values.append(try parseValue())
            token = try lexer.forceNext()
        } while token.token == .comma

        if token.token != .rightSquareBracket {
            throw JSONError.unexpectedToken(token.token, token.position)
        }
        
        return JSONArray(values: values, internalWhitespace: internalWhitespace)
    }

    func parseObject() throws -> JSONObject {
        let internalWhitespace = try lexer.takeWhitespace()
        if try lexer.peek()?.token == .rightCurlyBracket {
            let _ = try lexer.next()
            return JSONObject(keyValues: [], internalWhitespace: internalWhitespace)
        }
        
        var keyValues: [JSONKeyValue] = []
        var token: PositionedToken
        repeat {
            keyValues.append(try parseKeyValue())
            token = try lexer.forceNext()
        } while token.token == .comma
        
        if token.token != .rightCurlyBracket {
            throw JSONError.unexpectedToken(token.token, token.position)
        }
        
        return JSONObject(keyValues: keyValues, internalWhitespace: internalWhitespace)
    }
    
    func parseKeyValue() throws -> JSONKeyValue {
        let key = try parseKey()
        let token = try lexer.forceNext()
        if token.token != .colon {
            throw JSONError.unexpectedToken(token.token, token.position)
        }
        let value = try parseValue()
        return JSONKeyValue(key: key, value: value)
    }
    
    func parseKey() throws -> JSONKey {
        let prefixWhitespace = try lexer.takeWhitespace()
        let token = try lexer.forceNext()
        guard case let .string(key) = token.token else {
            throw JSONError.unexpectedToken(token.token, token.position)
        }
        let postfixWhitespace = try lexer.takeWhitespace()
        return JSONKey(prefixWhitespace: prefixWhitespace,
                       postfixWhitespace: postfixWhitespace,
                       key: key)
    }
    
    private let lexer: PeekableLexer
}

// MARK: A wrapper around JSONLexer

class PeekableLexer {
    init(_ lexer: JSONLexer) {
        self.lexer = lexer
    }

    func peek() throws -> PositionedToken? {
        if let nextToken = token {
            return nextToken
        } else {
            token = try lexer.next()
            return token
        }
    }
    
    func next() throws -> PositionedToken? {
        if let nextToken = token {
            token = nil
            return nextToken
        } else {
            return try lexer.next()
        }
    }

    func forceNext() throws -> PositionedToken {
        guard let token = try next() else {
            throw JSONError.unexpectedEndOfData(lexer.positionOfNextToken)
        }
        return token
    }
    
    func takeWhitespace() throws -> String {
        if let positionedToken = try peek(), case let .whitespace(whitespaceString) = positionedToken.token {
            let _ = try next()
            return whitespaceString
        }

        return ""
    }
    
    private let lexer: JSONLexer
    private var token: PositionedToken?
}

// MARK: String parsing

extension JSONElement {
    public var stringValue: String? {
        switch self {
        case .string(let unparsedString):
            return parse(string: unparsedString)
            
        default:
            return nil
        }
    }
    
    // We assume here that the string is a correctly formed unparsed JSON string, since it will always come from 
    // the lexer.
    // We work on UTF-16 characters (unichar) in the outputhere, since JSON only allows 16-bit literals (\uxxxx) and we 
    // need to join surrogate pairs.
    func parse(string: String) -> String {
        var output: [unichar] = []
        var iterator = string.unicodeScalars.makeIterator()
        while let scalar = iterator.next() {
            if scalar == "\\" {
                output += [parseSpecialCharacter(iterator: &iterator)]
            } else {
                output += utf16Array(from: scalar)
            }
        }
        return String(utf16CodeUnits: output, count: output.count)
    }
    
    func utf16Array(from unicodeScalar: UnicodeScalar) -> [unichar] {
        return Array(String(unicodeScalar).utf16)
    }
    
    func parseSpecialCharacter(iterator: inout String.UnicodeScalarView.Iterator) -> unichar {
        guard let scalar = iterator.next() else {
            fatalError("unparsed string not well-formed; non-closed escape sequence")
        }
        switch scalar {
        case "\"":
            return unichar(0x22)
        case "\\":
            return unichar(0x5C)
        case "/":
            return unichar(0x2F)
        case "b":
            return unichar(0x08)
        case "f":
            return unichar(0x0C)
        case "n":
            return unichar(0x0A)
        case "r":
            return unichar(0x0D)
        case "t":
            return unichar(0x09)
        case "u":
            return parseUnicodeHexLiteral(iterator: &iterator)
        default:
            fatalError("unparsed string not well-formed; unknown escape sequence")
        }
    }
    
    func parseUnicodeHexLiteral(iterator: inout String.UnicodeScalarView.Iterator) -> unichar {
        guard let a = iterator.next(), let b = iterator.next(), let c = iterator.next(), let d = iterator.next() else {
            fatalError("unparsed string not well-formed; \\u not followed by four characters")
        }
        let string = "\(a)\(b)\(c)\(d)"
        guard let integer = Int(string, radix: 16)  else {
            fatalError("unparsed string not well-formed; \\u not followed by four hex characters")
        }
        return unichar(integer)
    }
}
