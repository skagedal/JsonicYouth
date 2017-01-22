//
//  Created by Simon Kågedal Reimer on 2017-01-08.
//  Copyright © 2017 SKR. All rights reserved.
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
        if let extraToken = try lexer.next() {
            throw JSONError.unexpectedToken(extraToken, .zero) // TODO: position
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
        
        switch token {
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
            throw JSONError.unexpectedToken(token, .zero) // TODO: position
        }
    }
    
    func parseArray() throws -> JSONArray {
        let internalWhitespace = try lexer.takeWhitespace()
        if try lexer.peek() == .rightSquareBracket {
            let _ = try lexer.next()
            return JSONArray(values: [], internalWhitespace: internalWhitespace)
        }

        var values: [JSONValue] = []
        var token: Token
        repeat {
            values.append(try parseValue())
            token = try lexer.forceNext()
        } while token == .comma

        if token != .rightSquareBracket {
            throw JSONError.unexpectedToken(token, .zero) // TODO: position
        }
        
        return JSONArray(values: values, internalWhitespace: internalWhitespace)
    }

    func parseObject() throws -> JSONObject {
        let internalWhitespace = try lexer.takeWhitespace()
        if try lexer.peek() == .rightCurlyBracket {
            let _ = try lexer.next()
            return JSONObject(keyValues: [], internalWhitespace: internalWhitespace)
        }
        
        var keyValues: [JSONKeyValue] = []
        var token: Token
        repeat {
            keyValues.append(try parseKeyValue())
            token = try lexer.forceNext()
        } while token == .comma
        
        if token != .rightCurlyBracket {
            throw JSONError.unexpectedToken(token, .zero) // TODO: position
        }
        
        return JSONObject(keyValues: keyValues, internalWhitespace: internalWhitespace)
    }
    
    func parseKeyValue() throws -> JSONKeyValue {
        let key = try parseKey()
        let token = try lexer.forceNext()
        if token != .colon {
            throw JSONError.unexpectedToken(token, .zero) // TODO: position
        }
        let value = try parseValue()
        return JSONKeyValue(key: key, value: value)
    }
    
    func parseKey() throws -> JSONKey {
        let prefixWhitespace = try lexer.takeWhitespace()
        let token = try lexer.forceNext()
        guard case let .string(key) = token else {
            throw JSONError.unexpectedToken(token, .zero) // TODO: position
        }
        let postfixWhitespace = try lexer.takeWhitespace()
        return JSONKey(prefixWhitespace: prefixWhitespace,
                       postfixWhitespace: postfixWhitespace,
                       key: key)
    }
    
    private let lexer: PeekableLexer
}

class PeekableLexer {
    init(_ lexer: JSONLexer) {
        self.lexer = lexer
    }

    func peek() throws -> Token? {
        if let nextToken = token {
            return nextToken
        } else {
            token = try lexer.next()
            return token
        }
    }
    
    func next() throws -> Token? {
        if let nextToken = token {
            token = nil
            return nextToken
        } else {
            return try lexer.next()
        }
    }

    func forceNext() throws -> Token {
        guard let token = try next() else {
            throw JSONError.unexpectedEndOfData(.zero) // TODO: position
        }
        return token
    }
    
    func takeWhitespace() throws -> String {
        if let token = try peek(), case let .whitespace(whitespaceString) = token {
            let _ = try next()
            return whitespaceString
        }

        return ""
    }
    
    private let lexer: JSONLexer
    private var token: Token?
}
