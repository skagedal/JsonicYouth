//
//  Copyright © 2017 Simon Kågedal Reimer. MIT license; see LICENSE file.
//

public enum JSONError: Error {
    case encoding
    case unexpectedEndOfData(TextPosition)
    case unexpectedUnicodeScalar(UnicodeScalar, TextPosition)
    case unexpectedToken(Token, TextPosition)
}
