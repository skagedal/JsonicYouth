//
//  Created by Simon Kågedal Reimer on 2017-01-27.
//  Copyright © 2017 SKR. All rights reserved.
//

import XCTest
@testable import JsonicYouth

class TextPositionTests: XCTestCase {

    func testTextPosition() {
        var p = TextPosition.zero
        XCTAssertEqual(p.rows, 0)
        XCTAssertEqual(p.totalScalars, 0)
        XCTAssertEqual(p.scalarsInRow, 0)
        
        p = p.advanced(byNonNewlineScalars: 5)
        XCTAssertEqual(p.rows, 0)
        XCTAssertEqual(p.totalScalars, 5)
        XCTAssertEqual(p.scalarsInRow, 5)
        
        p = p.advanced(byNewlines: 10)
        XCTAssertEqual(p.rows, 10)
        XCTAssertEqual(p.totalScalars, 15)
        XCTAssertEqual(p.scalarsInRow, 0)
        
        p = p.advanced(by: "a\nb")
        XCTAssertEqual(p.rows, 11)
        XCTAssertEqual(p.totalScalars, 18)
        XCTAssertEqual(p.scalarsInRow, 1)
    }

}
