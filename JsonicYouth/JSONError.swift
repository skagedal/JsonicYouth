//
//  Created by Simon Kågedal Reimer on 2017-01-15.
//  Copyright © 2017 SKR. All rights reserved.
//

public enum JSONError: Error {
    case encoding
    case unexpectedEndOfData(TextPosition)
    case unexpectedUnicodeScalar(UnicodeScalar, TextPosition)
}
