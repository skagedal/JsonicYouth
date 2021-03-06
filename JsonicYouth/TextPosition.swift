//
//  Copyright © 2017 Simon Kågedal Reimer. MIT license; see LICENSE file.
//

public struct TextPosition {
    public let totalScalars: Int
    public let rows: Int
    public let scalarsInRow: Int
    
    static let zero = TextPosition(totalScalars: 0, rows: 0, scalarsInRow: 0)
    
    func advanced(byNonNewlineScalars scalars: Int) -> TextPosition {
        return TextPosition(totalScalars: totalScalars + scalars,
                            rows: rows,
                            scalarsInRow: scalarsInRow + scalars)
    }
    
    func advanced(byNewlines newlines: Int) -> TextPosition {
        return TextPosition(totalScalars: totalScalars + newlines,
                            rows: rows + newlines,
                            scalarsInRow: 0)
    }
    
    func advanced(by scalar:UnicodeScalar) -> TextPosition {
        if scalar == "\n" {
            return advanced(byNewlines: 1)
        } else {
            return advanced(byNonNewlineScalars: 1)
        }
    }
    
    func advanced(by string:String) -> TextPosition {
        var position = self
        for scalar in string.unicodeScalars {
            position = position.advanced(by: scalar)
        }
        return position
    }
}

extension TextPosition: Equatable {
    public static func ==(lhs: TextPosition, rhs: TextPosition) -> Bool {
        return lhs.totalScalars == rhs.totalScalars &&
            lhs.rows == rhs.rows &&
            lhs.scalarsInRow == rhs.scalarsInRow
    }
}
