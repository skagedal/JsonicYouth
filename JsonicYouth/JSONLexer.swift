//
//  Created by Simon Kågedal Reimer on 2017-01-15.
//  Copyright © 2017 SKR. All rights reserved.
//

public enum Token {
    case whitespace(String)
    case string(String)
    case number(String)
    case keyword(String)
    case leftSquareBracket
    case rightSquareBracket
    case leftCurlyBracket
    case rightCurlyBracket
    case comma
    case colon
}

extension Token: Equatable {
    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.whitespace(let a), .whitespace(let b)):
            return a == b
        case (.string(let a), .string(let b)):
            return a == b
        case (.number(let a), .number(let b)):
            return a == b
        case (.keyword(let a), .keyword(let b)):
            return a == b
        case (.leftSquareBracket, .leftSquareBracket),
             (.rightSquareBracket, .rightSquareBracket),
             (.leftCurlyBracket, .leftCurlyBracket),
             (.rightCurlyBracket, .rightCurlyBracket),
             (.comma, .comma),
             (.colon, .colon):
            return true
        default:
            return false
        }
    }
}

public protocol UnicodeScalarIterator {
    mutating func next() -> UnicodeScalar?
}

extension String.UnicodeScalarView.Iterator: UnicodeScalarIterator {
    
}

private enum State {
    // Whitespace is the start state
    case whitespace
    
    // String parsing states
    case string
    case afterBackslash
    case hexDigits(Int)
    
    // Number parsing states
    case afterMinus
    case afterZero
    case integerDigits
    case afterDot
    case fractionDigits
    case afterE
    case afterESign
    case exponentialDigits
    
    // Keyword parsing states
    case keyword(String, String)
    
    // Special states
    case rescan
    case error
    case end
}

// This is unfortunate, but since we have some states with associated values, the enum is no longer equatable.
// Not sure what is simpler/prettier, these accessors or implementing Equatable.
private extension State {
    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }
    var isEnd: Bool {
        switch self {
        case .end:
            return true
        default:
            return false
        }
    }
    var isRescan: Bool {
        switch self {
        case .rescan:
            return true
        default:
            return false
        }
    }
}

public class JSONLexer {
    public init(iterator: UnicodeScalarIterator) {
        self.iterator = iterator
    }
    
    public convenience init(string: String) {
        self.init(iterator: string.unicodeScalars.makeIterator())
    }
    
    public func next() throws -> Token? {
        if tokenQueue.isEmpty {
            try parseTokens()
        }
        return tokenQueue.isEmpty ? nil : tokenQueue.removeFirst()
    }
    
    public var position = TextPosition.zero

    private func parseTokens() throws {
        while tokenQueue.isEmpty && !state.isEnd {
            state = try readAndTransition()
        }
    }
    
    private func readAndTransition() throws -> State {
        if let scalar = iterator.next() {
            return try transition(on: scalar)
        } else {
            return try transitionOnEndOfFile()
        }
    }
    
    private func transition(on scalar: UnicodeScalar) throws -> State {
        let nextState = transition(from: state, on: scalar)
        if nextState.isError {
            throw JSONError.unexpectedUnicodeScalar(scalar, position)
        }
        if nextState.isRescan {
            state = .whitespace
            return try transition(on: scalar)
        }
        position = position.advanced(by: scalar)
        
        return nextState
    }
    
    private func transitionOnEndOfFile() throws -> State {
        let nextState = transitionOnEndOfFile(from: state)
        if case .error = nextState {
            throw JSONError.unexpectedEndOfData(position)
        }
        if nextState.isRescan {
            state = .whitespace
            return try transitionOnEndOfFile()
        }
        return nextState
    }
    
    
    private var iterator: UnicodeScalarIterator
    private var tokenQueue: [Token] = []
    private var currentTokenString = ""
    private var state = State.whitespace
    
    private func transition(from state: State, on scalar: UnicodeScalar) -> State {
        let scalarString = String(scalar)
        switch (state, scalar) {

        // Single character tokens

        case (.whitespace, "{"):
            emitWhitespace()
            emit(.leftCurlyBracket)
            return .whitespace
            
        case (.whitespace, "}"):
            emitWhitespace()
            emit(.rightCurlyBracket)
            return .whitespace
            
        case (.whitespace, "["):
            emitWhitespace()
            emit(.leftSquareBracket)
            return .whitespace
            
        case (.whitespace, "]"):
            emitWhitespace()
            emit(.rightSquareBracket)
            return .whitespace
            
        case (.whitespace, ","):
            emitWhitespace()
            emit(.comma)
            return .whitespace
            
        case (.whitespace, ":"):
            emitWhitespace()
            emit(.colon)
            return .whitespace
            
        // Numbers
            
        case (.whitespace, "-"):
            emitWhitespace()
            currentTokenString = scalarString
            return .afterMinus
            
        case (.whitespace, "0"):
            emitWhitespace()
            currentTokenString = scalarString
            return .afterZero
            
        case (.whitespace, "1"..."9"):
            emitWhitespace()
            currentTokenString = scalarString
            return .integerDigits
            
        case (.afterMinus, "0"):
            currentTokenString += scalarString
            return .afterZero
            
        case (.afterMinus, "1"..."9"):
            currentTokenString += scalarString
            return .integerDigits
            
        case (.integerDigits, "0"..."9"):
            currentTokenString += scalarString
            return .integerDigits
            
        case (.afterZero, "."), (.integerDigits, "."):
            currentTokenString += scalarString
            return .afterDot
            
        case (.afterDot, "0"..."9"), (.fractionDigits, "0"..."9"):
            currentTokenString += scalarString
            return .fractionDigits
            
        case (.afterZero, "e"), (.afterZero, "E"),
             (.integerDigits, "e"), (.integerDigits, "E"),
             (.fractionDigits, "e"), (.fractionDigits, "E"):
            currentTokenString += scalarString
            return .afterE
            
        case (.afterE, "+"), (.afterE, "-"):
            currentTokenString += scalarString
            return .afterESign
            
        case (.afterE, "0"..."9"), (.afterESign, "0"..."9"), (.exponentialDigits, "0"..."9"):
            currentTokenString += scalarString
            return .exponentialDigits
            
        case (.afterZero, _), (.integerDigits, _), (.fractionDigits, _), (.exponentialDigits, _):
            emitNumber()
            return .rescan

        // Keywords (true, false null)
            
        case (.whitespace, "t"):
            emitWhitespace()
            return .keyword("t", "rue")
            
        case (.whitespace, "f"):
            emitWhitespace()
            return .keyword("f", "alse")
            
        case (.whitespace, "n"):
            emitWhitespace()
            return .keyword("n", "ull")
            
        case (.keyword(let scanned, let expected), let s) where expected.unicodeScalars.first == s:
            if expected.unicodeScalars.count == 1 {
                emit(.keyword(scanned + expected))
                return .whitespace
            } else {
                return .keyword(scanned + String(s), String(expected.unicodeScalars.dropFirst()))
            }
            
        // Strings
            
        case (.whitespace, "\""):
            emitWhitespace()
            return .string
            
        case (.string, "\""):
            emitString()
            return .whitespace
            
        case (.string, "\\"):
            currentTokenString += scalarString
            return .afterBackslash
            
        case (.afterBackslash, let s) where s.isSimpleEscapedCharacter:
            currentTokenString += scalarString
            return .string
            
        case (.afterBackslash, "u"):
            currentTokenString += scalarString
            return .hexDigits(0)

        case (.hexDigits(let count), let s) where s.isHexDigit:
            currentTokenString += scalarString
            return count < 3 ? .hexDigits(count + 1) : .string
            
        case (.string, let s) where !s.isControlCharacter:
            currentTokenString += String(scalar)
            return .string
            
        // Whitespace
            
        case (.whitespace, let s) where s.isWhitespace:
            currentTokenString += scalarString
            return .whitespace
            
        // Everything else is an unexpected character
            
        default:
            return .error
        }
    }
    
    private func transitionOnEndOfFile(from state: State) -> State {
        switch state {
        case .whitespace:
            emitWhitespace()
            return .end
            
        case .afterZero, .integerDigits, .fractionDigits, .exponentialDigits:
            emitNumber()
            return .end
            
        case .end:
            return .end
            
        default:
            return .error
        }
    }
    
    private func emitWhitespace() {
        if !currentTokenString.isEmpty {
            emit(.whitespace(currentTokenString))
            currentTokenString = ""
        }
    }
    
    private func emitString() {
        emit(.string(currentTokenString))
        currentTokenString = ""
    }
    
    private func emitNumber() {
        emit(.number(currentTokenString))
        currentTokenString = ""
    }
    
    private func emit(_ token: Token) {
        tokenQueue += [token]
    }
}

private extension UnicodeScalar {
    var isWhitespace: Bool {
        switch self {
        case "\t", "\n", "\r", " ":
            return true
        default:
            return false
        }
    }
    
    var isSimpleEscapedCharacter: Bool {
        switch self {
        case "\"", "\\", "/", "b", "f", "n", "r", "t":
            return true
        default:
            return false
        }
    }
    
    var isHexDigit: Bool {
        switch self {
        case "0"..."9", "a"..."f", "A"..."F":
            return true
        default:
            return false
        }
    }
    
    var isControlCharacter: Bool {
        return self < " "
    }
}
