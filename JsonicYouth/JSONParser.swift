//
//  Created by Simon Kågedal Reimer on 2017-01-08.
//  Copyright © 2017 SKR. All rights reserved.
//

enum JSONElement {
    case object([JSONKeyValue])
    case array([JSONElement])
    case number(String)
    case string(String)
    case bool(Bool)
    case null
}

struct JSONValue {
    let position: TextPosition
    let prefixWhitespace: String
    let postfixWhitespace: String
    let element: JSONElement
}

struct JSONKey {
    let position: TextPosition
    let prefixWhitespace: String
    let postfixWhitespace: String
    let key: String
}

struct JSONKeyValue {
    let key: JSONKey
    let value: JSONValue
}
