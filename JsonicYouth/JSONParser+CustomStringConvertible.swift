//
//  Copyright © 2017 Simon Kågedal Reimer. MIT license; see LICENSE file.
//

extension JSONValue: CustomStringConvertible {
    public var description: String {
        return "\(prefixWhitespace)\(element)\(postfixWhitespace)"
    }
}

extension JSONElement: CustomStringConvertible {
    public var description: String {
        switch self {
        case .object(let object):
            return "\(object)"
        
        case .array(let array):
            return "\(array)"
            
        case .number(let string):
            return string
        
        case .string(let string):
            return "\"\(string)\""
            
        case .bool(true):
            return "true"
            
        case .bool(false):
            return "false"
            
        case .null:
            return "null"
        }
    }
}

extension JSONObject: CustomStringConvertible {
    public var description: String {
        let keyValuesStrings = keyValues.map { "\($0)" }
        let joined = keyValuesStrings.joined(separator: ",")
        return "{\(internalWhitespace)\(joined)}"
    }
}

extension JSONArray: CustomStringConvertible {
    public var description: String {
        let valuesStrings = values.map { "\($0)" }
        let joined = valuesStrings.joined(separator: ",")
        return "[\(internalWhitespace)\(joined)]"
    }
}

extension JSONKeyValue: CustomStringConvertible {
    public var description: String {
        return "\(key):\(value)"
    }
}

extension JSONKey: CustomStringConvertible {
    public var description: String {
        return "\(prefixWhitespace)\"\(key)\"\(postfixWhitespace)"
    }
}
